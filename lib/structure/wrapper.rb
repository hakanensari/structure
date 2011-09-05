# Cf. https://github.com/rails/rails/blob/master/activesupport/lib/active_support/basic_object.rb
unless defined? BasicObject
  class BasicObject
    instance_methods.each do |m|
      undef_method(m) if m.to_s !~ /(?:^__|^nil?$|^send$|^object_id$)/
    end
  end
end

class Structure
  # Wraps a constant for lazy evaluation.
  #
  # Idea lifted from: http://github.com/soveran/ohm/
  class Wrapper < BasicObject
    def initialize(name)
      @name = name
    end

    def is_a?(klass)
      klass.to_s == @name.to_s
    end

    def nil?
      Wrapper == ::NilClass
    end

    def to_s
      @name.to_s
    end

    # Delegates called method to wrapped class.
    def method_missing(meth, *args, &block)
      @unwrapped ? super : unwrap.send(meth, *args, &block)
    ensure
      @unwrapped = false
    end

    def unwrap
      @unwrapped = true
      ::Kernel.const_get @name
    end
  end
end
