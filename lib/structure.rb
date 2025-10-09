# frozen_string_literal: true

require "structure/builder"

# A library for parsing data into immutable Ruby Data objects with type coercion
module Structure
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
      builder.instance_eval(&block) if block

      # @type var klass: untyped
      klass = Data.define(*builder.attributes)

      # Enable custom method definitions by evaluating block on the class
      if block
        # Provide temporary dummy DSL methods to prevent NoMethodError during class_eval
        klass.define_singleton_method(:attribute) { |*args, **kwargs, &blk| }
        klass.define_singleton_method(:attribute?) { |*args, **kwargs, &blk| }
        klass.define_singleton_method(:after_parse) { |&blk| }

        # Evaluate block in class context for method definitions
        klass.class_eval(&block)

        # Remove temporary DSL methods
        klass.singleton_class.send(:remove_method, :attribute)
        klass.singleton_class.send(:remove_method, :attribute?)
        klass.singleton_class.send(:remove_method, :after_parse)
      end

      # Override initialize to make optional attributes truly optional
      optional_attrs = builder.optional
      unless optional_attrs.empty?
        klass.class_eval do
          alias_method(:__data_initialize__, :initialize)

          define_method(:initialize) do |**kwargs| # steep:ignore
            optional_attrs.each do |attr|
              kwargs[attr] = nil unless kwargs.key?(attr)
            end
            __data_initialize__(**kwargs) # steep:ignore
          end
        end
      end

      builder.predicate_methods.each do |pred, attr|
        klass.define_method(pred) { !!public_send(attr) }
      end

      # Store metadata on class to avoid closure capture (memory optimization)
      meta = {
        types: builder.types,
        defaults: builder.defaults,
        mappings: builder.mappings,
        coercions: builder.coercions(klass),
        after_parse: builder.after_parse_callback,
        required: builder.required,
      }.freeze
      klass.instance_variable_set(:@__structure_meta__, meta)
      klass.singleton_class.attr_reader(:__structure_meta__)

      # recursive to_h
      klass.define_method(:to_h) do
        klass.members.to_h do |m|
          v = public_send(m)
          value = case v
          when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
          when ->(x) { x.respond_to?(:to_h) && x } then v.to_h
          else v
          end
          [m, value]
        end
      end

      # parse accepts JSON-ish hashes + optional overrides hash
      # overrides is a positional arg (not **kwargs) to avoid hash allocation when unused
      #
      # @type self: singleton(Data) & _StructuredDataClass
      # @type var final: Hash[Symbol, untyped]
      klass.singleton_class.define_method(:parse) do |data = {}, overrides = nil|
        return data if data.is_a?(self)

        unless data.respond_to?(:merge!)
          raise TypeError, "can't convert #{data.class} into #{self}"
        end

        overrides&.each { |k, v| data[k.to_s] = v }

        final       = {}
        mappings    = __structure_meta__[:mappings]
        defaults    = __structure_meta__[:defaults]
        after_parse = __structure_meta__[:after_parse]
        required    = __structure_meta__[:required]

        # Check for missing required attributes
        required.each do |attr|
          from = mappings[attr]
          next if data.key?(from) || data.key?(from.to_sym) || defaults.key?(attr)

          raise ArgumentError, "missing keyword: :#{attr}"
        end

        mappings.each do |attr, from|
          value = data.fetch(from) do
            data.fetch(from.to_sym) do
              defaults[attr]
            end
          end

          if value
            coercion = __structure_meta__[:coercions][attr]
            value = coercion.call(value) if coercion
          end

          final[attr] = value
        end

        obj = new(**final)
        after_parse&.call(obj)
        obj
      end

      klass
    end
  end
end
