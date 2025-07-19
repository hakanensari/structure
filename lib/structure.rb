# frozen_string_literal: true

require_relative "structure/builder"

# A library for parsing data into immutable Ruby Data objects with type coercion
module Structure
  class << self
    def new(&block)
      builder = Builder.new
      builder.instance_eval(&block) if block

      data_class = Data.define(*builder.attributes)

      # Store builder data on the class
      data_class.define_singleton_method(:__structure_mappings) { builder.mappings }
      data_class.define_singleton_method(:__structure_types) { builder.types }
      data_class.define_singleton_method(:__structure_attributes) { builder.attributes }
      data_class.define_singleton_method(:__structure_predicate_methods) { builder.predicate_methods }
      data_class.define_singleton_method(:__structure_defaults) { builder.defaults }

      # Generate predicate methods
      builder.predicate_methods.each do |predicate_name, attribute_name|
        data_class.define_method(predicate_name) do
          send(attribute_name)
        end
      end

      data_class.define_singleton_method(:parse) do |data = {}, **kwargs|
        final_kwargs = {}
        __structure_attributes.each do |attr|
          source_key = __structure_mappings[attr]
          value = if kwargs.key?(attr)
            kwargs[attr]
          elsif data.key?(source_key)
            data[source_key]
          elsif data.key?(attr.to_s)
            data[attr.to_s]
          elsif data.key?(attr)
            data[attr]
          elsif __structure_defaults.key?(attr)
            __structure_defaults[attr]
          end

          # Apply type coercion or transformation
          if __structure_types[attr] && !value.nil?
            value = __structure_types[attr].call(value)
          end

          final_kwargs[attr] = value
        end
        new(**final_kwargs)
      end

      data_class
    end
  end
end
