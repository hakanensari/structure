# frozen_string_literal: true

# Structure
module Structure
  class << self
    private

    def included(base)
      base.extend(ClassMethods).instance_variable_set(:@attribute_names, [])
    end
  end

  def attributes
    attribute_names.reduce({}) do |hash, key|
      value = send(key)
      hash.update(
        key =>
          if value.respond_to?(:attributes)
            value.attributes
          elsif value.is_a?(::Array)
            value.map do |element|
              if element.respond_to?(:attributes)
                element.attributes
              else
                element
              end
            end
          else
            value
          end
      )
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
        if value.is_a?(Array)
          description = value.take(3).map(&:inspect).join(", ")
          description += "..." if value.size > 3
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

  # ClassMethods
  module ClassMethods
    attr_reader :attribute_names

    def attribute(name)
      name = name.to_s

      if name.chomp!('?')
        module_eval(<<-CODE, __FILE__, __LINE__ + 1)
          def #{name}?
            #{name}
          end
        CODE
      end

      module_eval(<<-CODE, __FILE__, __LINE__ + 1)
        def #{name}
          return @#{name} if defined?(@#{name})
          @#{name} = _#{name}
          @#{name}.freeze unless @#{name}.is_a?(Structure)

          @#{name}
        end
      CODE

      define_method("_#{name}", Proc.new)
      private "_#{name}"

      @attribute_names << name

      name.to_sym
    end

    private

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
    end
  end
end
