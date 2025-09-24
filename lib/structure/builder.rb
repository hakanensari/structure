# frozen_string_literal: true

require "structure/types"

module Structure
  # Builder class for accumulating attribute definitions
  class Builder
    attr_reader :mappings, :types, :defaults, :after_parse_callback

    def initialize
      @mappings = {}
      @types = {}
      @defaults = {}
    end

    # DSL method for defining attributes with optional type coercion
    #
    # @param name [Symbol] The attribute name
    # @param type [Class, Symbol, Array, nil] Type for coercion (e.g., String, :boolean, [String])
    # @param from [String, nil] Source key in the data hash (defaults to name.to_s)
    # @param default [Object, nil] Default value if attribute is missing
    # @yield [value] Block for custom transformation
    # @raise [ArgumentError] If both type and block are provided
    #
    # @example With type coercion
    #   attribute :age, Integer
    #
    # @example With custom source key
    #   attribute :created_at, Time, from: "CreatedAt"
    #
    # @example With transformation block
    #   attribute :price do |value|
    #     Money.new(value["amount"], value["currency"])
    #   end
    def attribute(name, type = nil, from: nil, default: nil, &block)
      @mappings[name] = from || name.to_s
      @defaults[name] = default unless default.nil?

      if type && block
        raise ArgumentError, "Cannot specify both type and block for :#{name}"
      elsif block
        @types[name] = block
      elsif type
        @types[name] = type
      end
    end

    # Defines a callback to run after parsing
    #
    # @yield [instance] Block that receives the parsed instance
    # @return [void]
    #
    # @example Validation
    #   after_parse do |order|
    #     raise "Invalid order" if order.total < 0
    #   end
    def after_parse(&block)
      @after_parse_callback = block
    end

    def attributes
      @mappings.keys
    end

    def coercions
      @types.transform_values { |type| Types.coerce(type) }
    end

    def predicate_methods
      @types.filter_map do |name, type|
        if type == :boolean
          ["#{name}?".to_sym, name] unless name.to_s.end_with?("?")
        end
      end.compact.to_h
    end
  end
end
