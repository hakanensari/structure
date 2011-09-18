class Structure
  # A namespaced basic object.
  #
  # When running a legacy Ruby version, we either quote Builder's Blank
  # Slate if available or fabricate a Basic Object ourselves.
  if defined?(BasicObject)
    BasicObject = ::BasicObject
  elsif defined?(BlankSlate)
    BasicObject = ::BlankSlate
  else
    class BasicObject
      instance_methods.each do |mth|
        undef_method(mth) unless mth =~ /\A(__|instance_eval)/
      end
    end
  end

  # A wrapper that lazy-evaluates a class.
  #
  # In psychoanalytic terms, this is a double that stands in for a yet-
  # to-be-defined class.
  #
  # Idea lifted from http://github.com/soveran/ohm/
  class Wrapper < BasicObject
    def initialize(name)
      @name = name
    end

    def to_s
      @name.to_s
    end

    def unwrap
      ::Kernel.const_get(@name)
    end

    private

    def method_missing(mth, *args, &block)
      @unwrapped ? super : @unwrapped = true
      unwrap.send(mth, *args, &block)
    ensure
      @unwrapped = false
    end
  end
end
