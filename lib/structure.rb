# frozen_string_literal: true

require 'structure/class_methods'

module Structure
  def self.inspect(value)
    if value.is_a?(::Array)
      inspection = value.take(3)
                        .map { |subvalue| inspect(subvalue) }
                        .join(', ')
      inspection += '...' if value.size > 3

      "[#{inspection}]"
    else
      value.inspect
    end
  end

  def self.serialize(value)
    if value.respond_to?(:attributes)
      value.attributes
    elsif value.is_a?(::Array)
      value.map { |subvalue| serialize(subvalue) }
    else
      value
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  # Returns a hash of all the attributes with their names as keys and the
  # values of the attributes as values
  def attributes
    attribute_names.each_with_object({}) do |key, hash|
      hash[key] = Structure.serialize(send(key))
    end
  end

  # Returns an array of attribute names as strings
  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    return false unless other.respond_to?(:attributes)

    attributes == other.attributes
  end

  def inspect
    name = self.class.name || self.class.to_s.gsub(/[^\w:]/, '')
    values = attribute_names
             .map { |key| "#{key}=#{Structure.inspect(send(key))}" }
             .join(', ')

    "#<#{name} #{values}>"
  end

  alias to_h attributes
  alias eql? ==
  alias to_s inspect
end
