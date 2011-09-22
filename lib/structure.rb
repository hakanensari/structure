# Structure is a typed key/value container.
#
#    class Person < Structure
#      key  :name
#      many :friends, Person
#    end
#
class Structure
  include Enumerable

  if defined?(BasicObject)
    BasicObject = ::BasicObject
  elsif defined?(BlankSlate)
    BasicObject = ::BlankSlate
  else
    class BasicObject
      instance_methods.each { |m|  undef_method(m) unless m =~ /__/ }
    end
  end

  # A wrapper for undeclared constants.
  #
  # Inspired by the same-named class in Ohm.
  class Wrapper < BasicObject
    def initialize(name)
      @name = name.to_s
    end

    def unwrap
      ::Kernel.const_get(@name)
    end

    def method_missing(mth, *args, &block)
      @unwrapped ? super : @unwrapped = true
      unwrap.send(mth, *args, &block)
    ensure
      @unwrapped = false
    end
  end

  # An attribute definition.
  class Definition < Struct.new(:name, :type, :default)
    def typecast(val)
      if val.nil? || val.is_a?(unwrapped_type)
        val.dup rescue val
      elsif Kernel.respond_to?(type.to_s)
        Kernel.send(type.to_s, val)
      else
        raise TypeError, "#{val} isn't a #{type}"
      end
    end

    def unwrapped_type
      @unwrapped_type ||= type.unwrap rescue type
    end
  end

  # A blueprint for a structure.
  class Blueprint < Array
    # A hash of attribute names and default values.
    def defaults
      inject({}) do |a, defn|
        val = defn.default.dup rescue defn.default
        a.merge({ defn.name => val })
      end
    end
  end

  # A collection of attribute definitions.
  def self.blueprint
    @blueprint ||= Blueprint.new
  end

  # Defines an attribute.
  #
  # Takes a name and optionally, a type and default value. Type
  # defaults to String if none is provided.
  def self.key(name, type = String, default = nil)
    name = name.to_sym

    if method_defined?(name)
      raise NameError, "#{name} is taken"
    end

    unless default.nil? || default.is_a?(type)
      raise TypeError, "#{default} isn't a #{type}"
    end

    blueprint << (defn = Definition.new(name, type, default))

    define_method(name) do
      attributes[name]
    end

    define_method("#{name}=") do |val|
      attributes[name] = defn.typecast(val)
    end
  end

  # Defines an attribute that is an array and default_attributes to an
  # empty one.
  def self.many(name)
    key name, Array, []
  end

  # Lazy-evaluate undefined constants.
  def self.const_missing(name)
    Wrapper.new(name)
  end

  # Creates a new structure.
  #
  # A hash, if provided, seeds the attributes.
  def initialize(hsh = {})
    @attributes = blueprint.defaults
    hsh.each { |k, v| self.send("#{k}=", v) }
  end

  # The attributes.
  attr :attributes

  # Calls block once for each attribute in the structure, passing that
  # attribute as a parameter.
  def each(&block)
    attributes.each { |v| block.call(v) }
  end

  # Converts structure to a hash.
  def to_hash
    attributes.inject({}) do |a, (k, v)|
      a[k] =
        if v.respond_to?(:to_hash)
          v.to_hash
        elsif v.is_a?(Array)
          v.map { |e| e.respond_to?(:to_hash) ? e.to_hash : e }
        else
          v
        end

      a
    end
  end

  # Compares this object with another object for equality. A Structure
  # is equal to the other object when both are of the same class and
  # the their attributes are the same.
  def ==(other)
    other.is_a?(self.class) && attributes == other.attributes
  end

  private

  def blueprint
    self.class.blueprint
  end
end
