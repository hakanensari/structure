module Structure
  def self.included(base)
    base
      .extend(ClassMethods)
      .instance_variable_set(:@value_names, [])
  end

  def values
    self.class.value_names.reduce({}) { |ret, name|
      ret.update(name => self.send(name))
    }
  end

  def ==(other)
    values == other.values
  end

  def inspect
    "#<#{self.class} #{
      values
        .map { |k, v| "#{k}=#{v.inspect}" }
        .join(', ')
    }>"
  end

  alias_method :to_h, :values
  alias_method :eql?, :==
  alias_method :to_s, :inspect

  module ClassMethods
    attr_reader :value_names

    def inherited(subclass)
      subclass.instance_variable_set(:@value_names, value_names.dup)
    end

    def value(name, &blk)
      @value_names << define_method(name, &blk)
    end
  end
end
