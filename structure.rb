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
        .map { |k, v| "#{k}=#{v.inspect}" }
        .join(', ')
    }>"
  end

  alias_method :to_h, :attributes
  alias_method :eql?, :==
  alias_method :to_s, :inspect

  module ClassMethods
    attr_reader :attribute_names

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, attribute_names.dup)
    end

    def attribute(name, &blk)
      @attribute_names << define_method(name, &blk)
    end
  end
end
