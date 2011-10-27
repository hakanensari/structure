# Structure is a typed key/value container
#
# @example
#    class Person < Structure
#      key :name
#      key :friends, Array, []
#    end
#
class Structure
  unless defined? BasicObject
    if defined? BlankSlate
      BasicObject = BlankSlate
    else
      class BasicObject
        instance_methods.each do |mth|
          undef_method(mth) unless mth =~ /__/
        end
      end
    end
  end

  # A wrapper for lazy-evaluating undeclared classes
  #
  # @note Somewhat borrowed from the same-named class in Ohm
  class Wrapper < BasicObject
    # Wraps specified class in a wrapper if it is not already wrapped
    #
    # @param [Class] klass a class, which may already be wrapped
    # @return [Wrapper] the wrapped class
    def self.wrap(klass)
      klass.class == self ? klass : new(klass.to_s)
    end

    # Creates a new wrapper for specified class name
    #
    # @param [#to_s] name
    def initialize(name)
      @name = name.to_s
    end

    # @return [Class] the class of the object
    def class
      Wrapper
    end

    # Unwraps wrapped class
    #
    # @return [Class] the unwrapped class
    def unwrap
      @name.split('::').inject(::Kernel) do |parent, child|
        parent.const_get(child)
      end
    end

    def method_missing(mth, *args, &block)
      @unwrapped ? super : @unwrapped = true
      ::Kernel.const_get(@name).send(mth, *args, &block)
    ensure
      @unwrapped = false
    end
  end

  # A key definition
  class Definition
    # Creates a key definition
    #
    # @param [Class] type the key type
    # @param [Object] default an optional default value
    def initialize(type, default = nil)
      @wrapper = Wrapper.wrap(type)
      @default = default
    end

    # @return the default value for the key
    attr :default

    # @return [Class] the key type
    def type
      @type ||= @wrapper.unwrap
    end

    # Typecasts specified value
    #
    # @param [Object] val a value
    # @raise [TypeError] value isn't a type
    # @return [Object] a typecast value
    def typecast(val)
      if val.nil? || val.is_a?(type)
        val.dup rescue val
      elsif Kernel.respond_to?(type.to_s)
        Kernel.send(type.to_s, val)
      else
        raise TypeError, "#{val} isn't a #{type}"
      end
    end
  end

  # A lambda that converts structures and arrays thereof, in any nested
  # shape or form, to hashes.
  HASHER = lambda { |obj|
    if obj.respond_to? :to_hash
      obj.to_hash
    elsif obj.is_a? Array
      obj.map { |e| HASHER.call(e) }
    else
      obj
    end
  }

  class << self
    # @return [Hash] a collection of keys and their definitions
    def blueprint
      @blueprint ||= {}
    end

    # Defines a key
    #
    # @note Key type defaults to +String+ if not specified.
    #
    # @param [#to_sym] name the key name
    # @param [Class] type an optional key type
    # @param [Object] default an optional default value
    # @raise [NameError] name is already taken
    def key(name, type = String, default = nil)
      if method_defined?(name = name.to_sym)
        raise NameError, "#{name} is taken"
      end

       if default && !default.is_a?(type)
        raise TypeError, "#{default} isn't a #{type}"
      end

      blueprint[name] = Definition.new(type, default)

      define_method(name) do
        @attributes[name]
      end

      define_method("#{name}=") do |val|
        @attributes[name] = blueprint[name].typecast(val)
      end
    end

    def const_missing(name)
      Wrapper.new(name)
    end
  end

  # Builds a new structure
  #
  # @param [Hash] hsh a hash of key-value pairs
  def initialize(hsh = {})
    @attributes = blueprint.inject({}) do |a, (k, v)|
      a[k] = v.default.dup rescue v.default
      a
    end

    hsh.each { |k, v| self.send("#{k}=", v) }
  end

  # @return [Hash] a hash representation of the structure
  def to_hash
    @attributes.inject({}) { |a, (k, v)| a.merge k => HASHER.call(v) }
  end

  # Compares this object with another object for equality
  #
  # A structure is equal to another object when both are of the same
  # class and their attributes are the same.
  #
  # @param [Object] other another object
  # @return [true, false]
  def ==(other)
    other.is_a?(self.class) && attributes == other.attributes
  end

  def blueprint
    self.class.blueprint
  end
  private :blueprint
end
