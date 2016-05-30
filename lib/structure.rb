module Structure
  class << self
    private

    def included(base)
      base.extend(ClassMethods).instance_variable_set(:@attribute_names, [])
    end
  end

  def attributes
    attribute_names.reduce({}) { |hash, key|
      value = send(key)
      hash.update(
        key =>
          if value.respond_to?(:attributes)
            value.attributes
          elsif value.is_a?(Array)
            value.map { |element|
              if element.respond_to?(:attributes)
                element.attributes
              else
                element
              end
            }
          else
            value
          end
      )
    }
  end

  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    return false unless other.respond_to?(:attributes)
    attributes == other.attributes
  end

  def inspect
    name = self.class.name || self.class.to_s.gsub(/[^\w:]/, "")
    values = attribute_names
      .map { |key|
        value = send(key)
        if (value).is_a?(Array)
          description = value.take(3).map(&:inspect).join(", ")
          description += "..." if value.size > 3
          "#{key}=[#{description}]"
        else
          "#{key}=#{value.inspect}"
        end
      }
      .join(", ")

    "#<#{name} #{values}>"
  end

  alias to_h attributes
  alias eql? ==
  alias to_s inspect

  module ClassMethods
    attr_reader :attribute_names

    def attribute(name)
      name = name.to_s

      if name.chomp!("?")
        module_eval(<<-EOS, __FILE__, __LINE__)
          def #{name}?
            #{name}
          end
        EOS
      end

      module_eval(<<-EOS, __FILE__, __LINE__)
        def #{name}
          return @#{name} if defined?(@#{name})
          @#{name} = _#{name}
          @#{name}.freeze unless @#{name}.is_a?(Structure)

          @#{name}
        end
      EOS

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
