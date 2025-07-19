# frozen_string_literal: true

module Structure
  # Type coercion methods for converting values to specific types
  module Types
    extend self

    # Rails-style boolean conversion
    # TRUE: true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'
    # FALSE: everything else (false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF', '', etc.)
    # Reference: https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html
    def boolean
      @boolean ||= ->(val) { [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].include?(val) }
    end

    # Generic handler for classes with kernel methods (String, Integer, Float, etc.)
    def kernel(type)
      ->(val) { Kernel.send(type.name, val) }
    end

    # Handler for nested Structure classes
    def structure(type)
      ->(val) { type.parse(val) }
    end

    # Create coercer for array elements
    def array(element_type)
      element_coercer = coerce(element_type)
      ->(array) { array.map { |element| element_coercer.call(element) } }
    end

    # Main factory method for creating type coercers
    def coerce(type)
      case type
      when :boolean
        boolean
      when Class
        if type.name && Kernel.respond_to?(type.name)
          kernel(type)
        elsif type.respond_to?(:parse)
          structure(type)
        else
          type
        end
      when Array
        if type.length == 1
          array(type.first)
        else
          type
        end
      else
        type
      end
    end
  end
end
