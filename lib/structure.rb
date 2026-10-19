# frozen_string_literal: true

require "structure/builder"

# A library for parsing data into immutable Ruby Data objects with type coercion
module Structure
  TO_H_CHECKER = Types.shareable(->(x) { x.respond_to?(:to_h) && x })
  private_constant :TO_H_CHECKER

  class << self
    # Creates a new Data class with attribute definitions and type coercion
    #
    # @yield [Builder] Block for defining attributes using the DSL
    # @return [Class] A Data class with a parse method
    #
    # @example Basic usage
    #   Person = Structure.new do
    #     attribute :name, String
    #     attribute :age, Integer
    #   end
    #
    #   person = Person.parse(name: "Alice", age: "30")
    #   person.name # => "Alice"
    #   person.age  # => 30
    def new(&block)
      builder = Builder.new
      builder.instance_eval(&block) if block # steep:ignore

      # @type var klass: untyped
      klass = Data.define(*builder.attributes)

      custom_methods_metadata = { instance: [].freeze, singleton: [].freeze }.freeze # steep:ignore

      # Enable custom method definitions by evaluating block on the class
      if block
        before_instance_methods = klass.instance_methods(false)
        before_singleton_methods = klass.singleton_methods(false)

        # Provide temporary dummy DSL methods to prevent NoMethodError during class_eval
        klass.define_singleton_method(:attribute) { |*args, **kwargs, &blk| }
        klass.define_singleton_method(:attribute?) { |*args, **kwargs, &blk| }
        klass.define_singleton_method(:after_parse) { |*args, &blk| }

        # Evaluate block in class context for method definitions
        klass.class_eval(&block)

        # Remove temporary DSL methods
        klass.singleton_class.send(:remove_method, :attribute)
        klass.singleton_class.send(:remove_method, :attribute?)
        klass.singleton_class.send(:remove_method, :after_parse)

        after_instance_methods = klass.instance_methods(false)
        after_singleton_methods = klass.singleton_methods(false)

        newly_defined_instance_methods = after_instance_methods - before_instance_methods
        newly_defined_singleton_methods = after_singleton_methods - before_singleton_methods

        instance_method_metadata = newly_defined_instance_methods.filter_map do |name|
          next unless klass.public_method_defined?(name)

          {
            name: name,
            parameters: Types.shareable(klass.instance_method(name).parameters),
          }.freeze
        end

        singleton_class = klass.singleton_class
        singleton_method_metadata = newly_defined_singleton_methods.filter_map do |name|
          next unless singleton_class.public_method_defined?(name)

          {
            name: name,
            parameters: Types.shareable(singleton_class.instance_method(name).parameters),
          }.freeze
        end

        custom_methods_metadata = {
          instance: instance_method_metadata.freeze,
          singleton: singleton_method_metadata.freeze,
        }.freeze
      end

      # Override initialize to make optional attributes truly optional
      optional_attrs = builder.optional.freeze
      unless optional_attrs.empty?
        klass.alias_method(:__data_initialize__, :initialize)

        # steep:ignore:start
        define_shareable_method(klass, :initialize) do |**kwargs|
          optional_attrs.each do |attr|
            kwargs[attr] = nil unless kwargs.key?(attr)
          end
          __data_initialize__(**kwargs)
        end
        # steep:ignore:end
      end

      builder.predicate_methods.each do |pred, attr|
        define_common_method(klass, pred) { !!public_send(attr) }
      end

      # Store metadata on class to avoid closure capture (memory optimization). What Structure builds of it is
      # frozen, so the whole is shareable when the caller's own types, defaults and blocks are, and then any
      # Ractor can parse.
      klass.instance_variable_set(:@__structure_meta__, {
        types: builder.types.freeze,
        defaults: builder.defaults.freeze,
        mappings: builder.mappings.freeze,
        coercions: builder.coercions(klass).freeze,
        after_parse: builder.after_parse_callback,
        required: builder.required.freeze,
        non_nullable: builder.non_nullable.freeze,
        custom_methods: custom_methods_metadata,
      }.freeze)
      define_common_method(klass.singleton_class, :__structure_meta__) do
        @__structure_meta__
      rescue Ractor::IsolationError
        raise Ractor::IsolationError,
          "#{self} parses only in the main Ractor: a type, block, default or after_parse callback is not shareable"
      end

      # recursive to_h
      define_shareable_method(klass, :to_h) do
        klass.members.to_h do |m|
          v = public_send(m)
          value = case v
          when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
          when TO_H_CHECKER then v.to_h
          else v
          end
          [m, value]
        end
      end

      # parse accepts JSON-ish hashes + optional overrides hash
      # overrides is a positional arg (not **kwargs) to avoid hash allocation when unused
      define_common_method(klass.singleton_class, :parse) do |data = {}, overrides = nil|
        # @type self: singleton(Data) & _StructuredDataClass
        # @type var final: Hash[Symbol, untyped]
        return data if data.is_a?(self)

        unless data.respond_to?(:merge!)
          raise TypeError, "can't convert #{data.class} into #{self}"
        end

        overrides&.each { |k, v| data[k.to_s] = v }

        final        = {}
        meta         = __structure_meta__
        mappings     = meta[:mappings]
        defaults     = meta[:defaults]
        coercions    = meta[:coercions]
        after_parse  = meta[:after_parse]
        required     = meta[:required]
        non_nullable = meta[:non_nullable]

        # Check for missing required attributes
        required.each do |attr|
          from = mappings[attr]
          next if data.key?(from) || data.key?(from.to_sym) || defaults.key?(attr)

          raise ArgumentError, "missing keyword: :#{attr}"
        end

        mappings.each do |attr, from|
          key_present = data.key?(from) || data.key?(from.to_sym)

          value = data.fetch(from) do
            data.fetch(from.to_sym) do
              defaults[attr]
            end
          end

          if value
            coercion = coercions[attr]
            value = coercion.call(value) if coercion
          end

          # Check non-null constraint after coercion
          # Only check if key was present in data OR attribute has an explicit default
          if value.nil? && non_nullable.include?(attr) && (key_present || defaults.key?(attr))
            raise ArgumentError, "cannot be null: :#{attr}"
          end

          final[attr] = value
        end

        obj = new(**final)
        after_parse&.call(obj)
        obj
      end

      define_common_method(klass.singleton_class, :load) { |data| parse(data) if data } # steep:ignore
      define_common_method(klass.singleton_class, :dump) { |value| value&.to_h }

      klass
    end

    private

    # Defines a method that any Ractor can call, not only the one that defined it. The block may read only locals
    # that hold shareable values and are assigned once.
    def define_shareable_method(target, name, &block)
      target.define_method(name, &Types.shareable(block))
    end

    # The same, for a method whose block is identical for every structure. The first block given for a name is
    # made shareable once and reused; later ones are ignored.
    def define_common_method(target, name, &block)
      @common_methods ||= {} # : Hash[Symbol, Proc]
      target.define_method(name, &(@common_methods[name] ||= Types.shareable(block)))
    end
  end
end
