module Structure
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@value_names, [])
  end

  def values
    vals = {}
    self.class.value_names.each { |name| vals[name] = self.send(name) }

    vals
  end

  def to_h
    Hash[values.dup.map { |k, v| [k, v.respond_to?(:to_h) ? v.to_h : v] } ]
  end

  def ==(other)
    values == other.values
  end
  alias :eql? :==

  def inspect
    str = "#<#{self.class}"

    first = true
    values.each do |k, v|
      str << ',' unless first
      first = false
      str << " #{k}=#{v.inspect}"
    end

    str << '>'
  end
  alias :to_s :inspect

  module ClassMethods
    attr :value_names

    def inherited(subclass)
      subclass.instance_variable_set(:@value_names, value_names.dup)
    end

    def value(name, &blk)
      define_method(name, &blk)
      @value_names << name
    end
  end
end
