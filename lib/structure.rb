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

  module ClassMethods
    attr :value_names

    def value(name, &blk)
      define_method(name, &blk)
      @value_names << name
    end
  end
end
