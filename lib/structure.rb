# frozen_string_literal: true

require "structure/builder"

# A library for parsing data into immutable Ruby Data objects with type coercion
module Structure
  class << self
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

      data_class.define_singleton_method(:parse) do |data = {}, **kwargs|
        final_kwargs = {}
        attributes.each do |attr|
          source_key = mappings[attr]
          value = if kwargs.key?(attr)
            kwargs[attr]
          elsif data.key?(source_key)
            data[source_key]
          elsif data.key?(attr.to_s)
            data[attr.to_s]
          elsif data.key?(attr)
            data[attr]
          elsif defaults.key?(attr)
            defaults[attr]
          end

          # Apply type coercion or transformation
          if types[attr] && !value.nil?
            value = types[attr].call(value)
          end

          final_kwargs[attr] = value
        end
        new(**final_kwargs)
      end

      data_class
    end
  end
end
