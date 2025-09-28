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

      # capture all metadata and attach to class - no closure capture needed
      mappings = builder.mappings
      coercions = builder.coercions(klass)
      predicates = builder.predicate_methods
      after = builder.after_parse_callback

      meta = {
        attributes: builder.attributes.freeze,
        types: builder.types.freeze,
        defaults: builder.defaults.freeze,
        mappings: mappings.freeze,
        coercions: coercions.freeze,
        predicates: predicates.freeze,
        after: after,
      }.freeze
      klass.instance_variable_set(:@__structure_meta__, meta)
      klass.singleton_class.attr_reader(:__structure_meta__)

      # Define predicate methods
      predicates.each do |pred, attr|
        klass.define_method(pred) { !!public_send(attr) }
      end

      # recursive to_h
      klass.define_method(:to_h) do
        # @type var h: Hash[Symbol, untyped]
        h = {}
        klass.members.each do |m|
          v = public_send(m)
          h[m] =
            case v
            when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
            when ->(x) { x.respond_to?(:to_h) && x } then v.to_h
            else v
            end
        end
        h
      end

      # parse accepts JSON-ish hashes + optional overrides hash
      klass.singleton_class.define_method(:parse) do |data = {}, overrides = nil|
        return data if data.is_a?(self)

        unless data.respond_to?(:merge!)
          raise TypeError, "can't convert #{data.class} into #{self}"
        end

        overrides&.each { |k, v| data[k.to_s] = v }
        # @type self: singleton(Data) & _StructuredDataClass
        # @type var final: Hash[Symbol, untyped]
        final = {}

        # @type var meta: untyped
        meta = __structure_meta__
        attributes = meta[:attributes]
        defaults = meta[:defaults]
        mappings = meta[:mappings]
        coercions = meta[:coercions]
        after = meta[:after]

        attributes.each do |attr|
          source = mappings.fetch(attr) { attr.to_s }
          value = data.fetch(source) do
            data.fetch(source.to_sym) do
              defaults[attr]
            end
          end

          coercion = coercions[attr]
          if coercion && !value.nil?
            # Procs (not lambdas) need class context for self-referential parsing
            # Lambdas and other callables use direct invocation
            value =
              if coercion.is_a?(Proc) && !coercion.lambda?
                instance_exec(value, &coercion) # steep:ignore
              else
                coercion.call(value)
              end
          end

          final[attr] = value
        end

        obj = new(**final)
        after&.call(obj)
        obj
      end

      klass
    end
  end
end
