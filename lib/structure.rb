module Structure
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def value(name, &blk)
      define_method(name, &blk)
    end
  end
end
