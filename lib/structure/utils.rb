# frozen_string_literal: true

module Structure
  module Utils
    def self.serialize(value)
      if value.respond_to?(:attributes)
        value.attributes
      elsif value.is_a?(::Array)
        value.map { |subvalue| serialize(subvalue) }
      else
        value
      end
    end
  end
end
