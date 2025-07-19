# frozen_string_literal: true

# A tiny library for lazy parsing data with memoized attributes
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
          source_key = __structure_mappings[attr] || attr.to_s
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

  class Builder
    attr_reader :attributes, :mappings, :types, :predicate_methods, :defaults

    def initialize
      @attributes = []
      @mappings = {}
      @types = {}
      @predicate_methods = {}
      @defaults = {}
    end

    def attribute(name, type = nil, from: nil, default: nil, &block)
      @attributes << name
      @mappings[name] = from if from
      @defaults[name] = default unless default.nil?

      if type && block
        raise ArgumentError, "Cannot specify both type and block for :#{name}"
      elsif block
        @types[name] = block
      elsif type
        @types[name] = if type == :boolean
          # Generate predicate method for any boolean attribute
          predicate_name = "#{name}?"
          @predicate_methods[predicate_name.to_sym] = name
          # Rails-style boolean conversion
          # TRUE: true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'
          # FALSE: everything else (false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF', '', etc.)
          ->(val) { [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].include?(val) }
        elsif type.is_a?(Class) && type.name && Kernel.respond_to?(type.name)
          # Generic handler for classes with kernel methods (String, Integer, Float, etc.)
          ->(val) { Kernel.send(type.name, val) }
        elsif type.is_a?(Array) && type.length == 1
          # Handle Array[Type] syntax
          element_type = type.first
          element_coercer = if element_type == :boolean
            ->(val) { [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].include?(val) }
          elsif element_type.is_a?(Class) && element_type.name && Kernel.respond_to?(element_type.name)
            ->(val) { Kernel.send(element_type.name, val) }
          elsif element_type.is_a?(Class) && element_type.respond_to?(:parse)
            ->(val) { element_type.parse(val) }
          else
            element_type
          end
          ->(array) { array.map { |element| element_coercer.call(element) } }
        elsif type.is_a?(Class) && type.respond_to?(:parse)
          # Handle nested Structure classes
          ->(val) { type.parse(val) }
        else
          type
        end
      end
    end
  end
end
