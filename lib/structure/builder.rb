# frozen_string_literal: true

require "structure/types"

module Structure
  # Builder class for accumulating attribute definitions
  class Builder
    attr_reader :mappings, :types, :defaults

    def initialize
      @mappings = {}
      @types = {}
      @defaults = {}
    end

    def attribute(name, type = nil, from: nil, default: nil, &block)
      # Always store in mappings - use attribute name as default source
      @mappings[name] = from || name.to_s
      @defaults[name] = default unless default.nil?

      if type && block
        raise ArgumentError, "Cannot specify both type and block for :#{name}"
      elsif block
        @types[name] = block
      elsif type
        @types[name] = Types.coerce(type)
      end
    end

    # Deduced from mappings - maintains order of definition
    def attributes
      @mappings.keys
    end

    # Deduced from types that are boolean
    def predicate_methods
      @types.filter_map do |name, type_lambda|
        if type_lambda == Types.boolean
          predicate_name = "#{name}?"
          [predicate_name.to_sym, name]
        end
      end.to_h
    end
  end
end
