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
      # @param type [Class, Symbol, Array] Type specification
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
      def coerce(type)
        case type
        when :boolean
          boolean
        when :self
          self_referential
        when Array
          if type.length == 1
            array(type.first)
          else
            type
          end
        else
          if type.respond_to?(:parse)
            parseable(type)
          elsif type.respond_to?(:name) && type.name && Kernel.respond_to?(type.name)
            kernel(type)
          else
            type
          end
        end
      end

      private

      def boolean
        @boolean ||= ->(val) { BOOLEAN_TRUTHY.include?(val) }
      end

      def self_referential
        proc { |val| parse(val) }
      end

      def kernel(type)
        ->(val) { Kernel.send(type.name, val) }
      end

      def parseable(type)
        ->(val) { type.parse(val) }
      end

      def array(element_type)
        if element_type == :self
          proc { |array| array.map { |element| parse(element) } }
        else
          element_coercer = coerce(element_type)
          ->(array) { array.map { |element| element_coercer.call(element) } }
        end
      end
    end
  end
end
