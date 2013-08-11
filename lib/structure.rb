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
  alias :to_h :values

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

    def value(name, &blk)
      define_method(name, &blk)
      @value_names << name
    end
  end
end
