# frozen_string_literal: true

module Structure
  # Type coercion methods for converting values to specific types
  module Types
    class << self
      # Rails-style boolean truthy values
      # Reference: https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html
      BOOLEAN_TRUTHY = [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].freeze
      private_constant :BOOLEAN_TRUTHY

      # Main factory method for creating type coercers
      #
      # @param type [Class, Symbol, Array, String] Type specification
      # @return [Proc, Object] Coercion proc or the type itself if no coercion available
      #
      # @example Boolean type
      #   coerce(:boolean) # => boolean proc
      #
      # @example Kernel types
      #   coerce(Integer) # => proc that calls Kernel.Integer
      #
      # @example Parseable types
      #   coerce(Date) # => proc that calls Date.parse
      #
      # @example Array types
      #   coerce([String]) # => proc that coerces array elements to String
      #
      # @example String class name (lazy resolved)
      #   coerce("MyClass") # => proc that resolves and coerces to MyClass
      def coerce(type, context_class = nil)
        case type
        when :boolean
          boolean
        when :self
          self_referential
        when String
          string_class(type, context_class)
        when ->(t) { t.is_a?(Array) && t.length == 1 }
          array(type.first, context_class)
        when Hash
          raise ArgumentError, "Cannot specify #{type.inspect} as type"
        when ->(t) { t.respond_to?(:parse) }
          parseable(type)
        when ->(t) { t.respond_to?(:name) && t.name && Kernel.respond_to?(t.name) }
          kernel(type)
        when ->(t) { t.respond_to?(:call) }
          type
        when nil
          type
        else
          raise ArgumentError, "Cannot specify #{type.inspect} as type"
        end
      end

      def resolve_class(class_name, context_class)
        if context_class && defined?(context_class.name)
          namespace = context_class.name.to_s.split("::")[0...-1]
          if namespace.any?
            begin
              namespace.reduce(Object) { |mod, name| mod.const_get(name) }.const_get(class_name)
            rescue NameError
              Object.const_get(class_name)
            end
          else
            Object.const_get(class_name)
          end
        else
          Object.const_get(class_name)
        end
      rescue NameError => e
        raise NameError, "Unable to resolve class '#{class_name}': #{e.message}"
      end

      private

      def boolean
        @boolean ||= ->(val) { BOOLEAN_TRUTHY.include?(val) }
      end

      def self_referential
        proc { |val| parse(val) }
      end

      def kernel(type)
        @kernel_cache ||= {} # : Hash[untyped, Proc]
        @kernel_cache[type] ||= ->(val) { Kernel.send(type.name, val) }
      end

      def parseable(type)
        @parseable_cache ||= {} # : Hash[untyped, Proc]
        @parseable_cache[type] ||= ->(val) { type.parse(val) }
      end

      def string_class(class_name, context_class)
        resolved_class = nil
        mutex = Mutex.new

        proc do |value|
          unless resolved_class
            mutex.synchronize do
              resolved_class ||= Structure::Types.resolve_class(class_name, context_class)
            end
          end

          if resolved_class.respond_to?(:parse)
            resolved_class.parse(value) # steep:ignore
          else
            value
          end
        end
      end

      def array(element_type, context_class = nil)
        if element_type == :self
          proc do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            value.map { |element| parse(element) }
          end
        elsif element_type.is_a?(String)
          proc do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            resolved_class = Structure::Types.resolve_class(element_type, context_class)
            value.map do |element|
              if resolved_class.respond_to?(:parse)
                resolved_class.parse(element)
              else
                element
              end
            end
          end
        else
          element_coercer = coerce(element_type, context_class)
          lambda do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            value.map { |element| element_coercer.call(element) }
          end
        end
      end
    end
  end
end
