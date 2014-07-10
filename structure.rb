module Structure
  def self.included(base)
    base
      .extend(ClassMethods)
      .instance_variable_set(:@attribute_names, [])
  end

  def attributes
    self.class.attribute_names.reduce({}) { |ret, name|
      ret.update(name => self.send(name))
    }
  end

  def ==(other)
    attributes == other.attributes
  end

  def inspect
    "#<#{self.class} #{
      attributes
        .map { |key, val| "#{key}=#{val.inspect}" }
        .join(', ')
    }>"
  end

  alias_method :to_h, :attributes
  alias_method :eql?, :==
  alias_method :to_s, :inspect

  module ClassMethods
    attr_reader :attribute_names

    def to_struct
      return Struct.const_get(name, false) if Struct.const_defined?(name, false)

      Struct.new(name, *attribute_names) do
        def initialize(data = {})
          data.each { |key, val| self.send("#{key}=", val) }
        end
      end
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
    end

    def attribute(name, &blk)
      define_method(name, &blk)
      @attribute_names << name
    end
  end
end
