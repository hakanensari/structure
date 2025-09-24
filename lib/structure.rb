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

      # capture builder state
      mappings = builder.mappings
      types    = builder.types
      defaults = builder.defaults
      attrs    = builder.attributes
      after    = builder.after_parse_callback

      # optional predicate methods
      builder.predicate_methods.each do |pred, attr|
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
        string_kwargs = kwargs.transform_keys(&:to_s)
        data = data.merge(string_kwargs)

        final = {}
        attrs.each do |attr|
          source = mappings[attr]
          value =
            if data.key?(source)            then data[source]
            elsif data.key?(source.to_sym)  then data[source.to_sym]
            elsif defaults.key?(attr)       then defaults[attr]
            end

          coercer = types[attr]
          if coercer && !value.nil?
            value =
              if coercer.is_a?(Proc) && !coercer.lambda?
                instance_exec(value, &coercer)
              else
                coercer.call(value)
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
