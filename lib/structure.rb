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

      klass = Data.define(*builder.attributes)

      # capture metadata and attach to class
      meta = {
        attributes: builder.attributes.freeze,
        types: builder.types.freeze,
        defaults: builder.defaults.freeze,
      }.freeze
      klass.instance_variable_set(:@__structure_meta__, meta)
      klass.singleton_class.attr_reader(:__structure_meta__)

      # capture locals for method generation
      mappings = builder.mappings
      coercions = builder.coercions
      predicates = builder.predicate_methods
      after = builder.after_parse_callback

      # Define predicate methods
      predicates.each do |pred, attr|
        klass.define_method(pred) { public_send(attr) }
      end

      # recursive to_h
      klass.define_method(:to_h) do
        self.class.members.each_with_object({}) do |m, h|
          v = public_send(m)
          h[m] =
            case v
            when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
            when ->(x) { x.respond_to?(:to_h) && x } then v.to_h
            else v
            end
        end
      end

      # parse accepts JSON-ish hashes + kwargs override
      klass.define_singleton_method(:parse) do |data = {}, **kwargs|
        return data if data.is_a?(self)

        string_kwargs = kwargs.transform_keys(&:to_s)
        data = data.merge(string_kwargs)

        final = {}
        meta = __structure_meta__

        meta[:attributes].each do |attr|
          source = mappings[attr] || attr.to_s
          value =
            if data.key?(source)            then data[source]
            elsif data.key?(source.to_sym)  then data[source.to_sym]
            elsif meta[:defaults].key?(attr) then meta[:defaults][attr]
            end

          coercion = coercions[attr]
          if coercion && !value.nil?
            # self-referential types need class context to call parse
            value =
              if coercion.is_a?(Proc) && !coercion.lambda?
                instance_exec(value, &coercion)
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
