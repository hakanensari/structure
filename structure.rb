module Structure
  def self.included(base)
    base.extend(ClassMethods).instance_variable_set(:@attribute_names, [])
  end

  def attributes
    attribute_names.reduce({}) { |ret, name|
      ret.update(name => self.send(name))
    }
  end

  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    attributes == other.attributes
  end

  def inspect
    class_name = self.class.name || self.class.to_s.match(/#<(.*)>/)[1]

    "#<#{class_name} #{
      attributes
        .map { |key, val|
          if val.is_a?(Array) && val.size > 3
            "#{key}=[#{val.take(3).map(&:inspect).join(', ')}...]"
          else
            "#{key}=#{val.inspect}"
          end
        }
        .join(', ')
    }>"
  end

  alias_method :to_h, :attributes
  alias_method :eql?, :==
  alias_method :to_s, :inspect

  module ClassMethods
    attr_reader :attribute_names

    def to_struct
      class_name = name || to_s.gsub(/\W/, '')

      if Struct.const_defined?(class_name, false)
        return Struct.const_get(class_name, false)
      end

      klass = Struct.new(class_name, *attribute_names) do
        def initialize(data = {})
          data.each { |key, val| self.send("#{key}=", val) }
        end
      end

      attribute_names.each do |name|
        if instance_methods(false).include?(:"#{name}?")
          klass.module_eval "def #{name}?; #{name}; end"
        end
      end

      klass
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
    end

    def attribute(name, &blk)
      name = name.to_s
      module_eval "def #{name}?; #{name}; end" if name.chomp!('?')
      module_eval "def #{name}; @#{name} ||= _#{name}; end"
      define_method("_#{name}", blk)
      private "_#{name}"

      @attribute_names << name
    end
  end
end
