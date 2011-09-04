class Structure
  # Wraps a constant for lazy evaluation.
  #
  # Idea lifted straight from: http://github.com/soveran/ohm/
  class Wrapper < BasicObject
    def initialize(name)
      @name, @wrapped = name, true
    end

    # Delegates called method to wrapped class.
    def method_missing(meth, *args, &block)
      @wrapped ? unwrap.send(meth, *args, &block) : super
    ensure
      @wrapped = true
    end

    def unwrap
      @wrapped = false
      ::Kernel.const_get @name
    end
  end
end
