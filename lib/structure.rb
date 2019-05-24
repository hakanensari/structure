# frozen_string_literal: true

require 'structure/class_methods'
require 'structure/utils'

module Structure
  def self.included(base)
    base.extend ClassMethods
    base.__overwrite_initialize__
  end

  def attributes
    attribute_names.each_with_object({}) do |key, hash|
      hash[key] = Utils.serialize(send(key))
    end
  end

  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    return false unless other.respond_to?(:attributes)

    attributes == other.attributes
  end

  def inspect
    name = self.class.name || self.class.to_s.gsub(/[^\w:]/, '')
    values =
      attribute_names
      .map do |key|
        value = send(key)
        if value.is_a?(::Array)
          description = value.take(3).map(&:inspect).join(', ')
          description += '...' if value.size > 3
          "#{key}=[#{description}]"
        else
          "#{key}=#{value.inspect}"
        end
      end
      .join(', ')

    "#<#{name} #{values}>"
  end

  alias to_h attributes
  alias eql? ==
  alias to_s inspect
end
