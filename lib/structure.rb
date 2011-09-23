begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a typed key/value container.
#
#    class Person < Structure
#      key :name
#      many :friends, Person
#    end
#
class Structure
  include Enumerable

  # Fabricate a Basic Object if it doesn't exist.
  unless defined?(BasicObject)
    if defined?(BlankSlate)
      BasicObject = ::BlankSlate
    else
      class BasicObject
        instance_methods.each { |m|  undef_method(m) unless m =~ /__/ }
      end
    end
  end

  # Wraps a class for lazy evaluation. Allows you to use a class even
  # before it is defined.
  #
  # Inspired by the same-named class in Ohm.
  class Wrapper < BasicObject
    def self.wrap(obj)
      obj.class == self ? obj : new(obj.inspect.to_sym)
    end

    def initialize(name)
      @name = name.to_s
    end

    def class
      Wrapper
    end

    def inspect
      "Wrapper for #{@name}"
    end

    def unwrap
      @name.split('::').inject(::Kernel) do |parent, child|
        parent.const_get(child)
      end
    end
  end

  # A collection is a typed array that loosely follows Active Record
  # conventions.
  class Collection < Array
    def initialize(klass)
      @wrapped = Wrapper.wrap(klass)
    end

    [:push, :unshift].each do |method|
      define_method(method) do |*items|
        enforce_type(items)
        super(*items)
      end
    end

    # We break with the original method definitions to follow Active
    # Record conventions here.
    [:<<, :concat].each { |method| alias_method method, :push }

    def []=(idx, item)
      enforce_type([item])
      super
    end

    def build(arg)
      self.<<(type.new(arg))
    end

    private

    def enforce_type(items)
      items.each do |item|
        unless item.is_a? type
          raise TypeError, "#{item} isn't a #{type}"
        end
      end
    end

    def type
      @type ||= @wrapped.unwrap
    end
  end

  # An attribute definition.
  class Definition < Struct.new(:name, :type, :default)
    def typecast(val)
      if val.nil? || val.is_a?(type.unwrap)
        val.dup rescue val
      elsif val.is_a?(Array) && type.unwrap == Collection
        default.dup.push(*val)
      elsif Kernel.respond_to?(type.unwrap.to_s)
        Kernel.send(type.unwrap.to_s, val)
      else
        raise TypeError, "#{val} isn't a #{type.unwrap}"
      end
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

  # Builds a structure out of its JSON representation.
  def self.json_create(hsh)
    hsh.delete('json_class')
    new(hsh)
  end

  # Defines an attribute.
  #
  # Takes a name and optionally, a type and default value. Type
  # defaults to String if none is provided.
  def self.key(name, type = String, default = nil)
    name = name.to_sym
    type = Wrapper.wrap(type)

    if method_defined?(name)
      raise NameError, "#{name} is taken"
    end

    unless default.nil? || default.is_a?(type.unwrap)
      raise TypeError, "#{default} isn't a #{type.unwrap}"
    end

    blueprint << (defn = Definition.new(name, type, default))

    define_method(name) do
      attributes[name]
    end

    define_method("#{name}=") do |val|
      attributes[name] = defn.typecast(val)
    end
  end

  # Defines an attribute that is a collection of objects of specified
  # type.
  def self.many(name, type)
    key name, Collection, Collection.new(type)
  end

  # Defines an attribute that is another structure.
  def self.one(name, type)
    type = Wrapper.wrap(type)

    key name, type

    define_method("build_#{name}") do |hsh|
      self.send("#{name}=", type.unwrap.new(hsh))
    end
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

  # Converts structure to its JSON representation.
  def to_json(*args)
    { JSON.create_id => self.class.name }.
      merge(attributes).
      to_json(*args)
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

  if defined? ActiveSupport
    require 'structure/ext/active_support'
  end
end