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

      data_class = Data.define(*builder.attributes)

      # Generate predicate methods
      builder.predicate_methods.each do |predicate_name, attribute_name|
        data_class.define_method(predicate_name) do
          send(attribute_name)
        end
      end

      # Capture builder data in closure for parse method
      mappings = builder.mappings
      types = builder.types
      defaults = builder.defaults
      attributes = builder.attributes
      after_parse_callback = builder.after_parse_callback

      data_class.define_singleton_method(:parse) do |data = {}, **kwargs|
        # Merge kwargs into data - kwargs take priority as overrides
        # Convert kwargs symbol keys to strings to match source_key lookups
        string_kwargs = kwargs.transform_keys(&:to_s)
        data = data.merge(string_kwargs)

        final_kwargs = {}
        attributes.each do |attr|
          source_key = mappings[attr]
          value = if data.key?(source_key)
            data[source_key]
          elsif data.key?(source_key.to_sym)
            data[source_key.to_sym]
          elsif defaults.key?(attr)
            defaults[attr]
          end

          # Apply type coercion or transformation
          if types[attr] && !value.nil?
            value = types[attr].call(value)
          end

          final_kwargs[attr] = value
        end

        instance = new(**final_kwargs)
        after_parse_callback&.call(instance)
        instance
      end

      data_class
    end
  end
end
