begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

require 'structure/inflector'
require 'structure/wrapper'

# Structure is a nestable, typed key/value container.
#
#    class Person < Structure
#      key  :name
#      many :friends
#    end
#
class Structure
  include Enumerable

  class << self
    # Returns attribute keys and their default values.
    def defaults
      @defaults ||= {}
    end

    # Recreates a structure out of its JSON representation.
    def json_create(hsh)
      hsh.delete('json_class')
      new(hsh)
    end

    # Defines an attribute.
    #
    # Takes a name and, optionally, a type and default value.
    def key(name, type = nil, default = nil)
      name = name.to_sym

      if method_defined?(name)
        raise NameError, "#{name} is taken"
      end

      if !default || !type || default.is_a?(type)
        defaults[name] = default
      else
        raise TypeError, "#{default} isn't a #{type}"
      end

      define_method(name) { attributes[name] }

      define_method("#{name}=") do |val|
        type = type.unwrap rescue type
        attributes[name] =
          if type.nil? || val.nil? || val.is_a?(type)
            val.dup rescue val
          elsif Kernel.respond_to?(type.to_s)
            Kernel.send(type.to_s, val)
          else
            raise TypeError, "#{val} isn't a #{type}"
          end
      end
    end

    # Defines an attribute that is an array and defaults to an empty
    # one.
    def many(name)
      key name, Array, []
    end

    alias_method :new_original, :new

    def new(hsh)
      hsh = hsh.inject({}) do |a, (k, v)|
        a[Inflector.underscore(k)] =
          case v
          when Hash
            Structure.new(v)
          when Array
            v.map { |e| e.is_a?(Hash) ? Structure.new(e) : e }
          else
            v
          end
        a
      end

      klass = Class.new(Structure) do
        hsh.keys.each { |k| key k }
      end

      klass.new(hsh)
    end

    private

    # Lazy-evaluate undefined constants, typically other structures,
    # assuming they will be defined later in the text.
    def const_missing(name)
      Wrapper.new(name)
    end

    def inherited(child)
      if self.eql? Structure
        class << child; alias_method :new, :new_original; end
      end
    end
  end

  # Creates a new structure.
  #
  # A hash, if provided, seeds the attributes.
  def initialize(hsh = {})
    @attributes = defaults.inject({}) do |a, (k, v)|
      a[k] = v.dup rescue v
      a
    end

    hsh.each { |k, v| self.send("#{k}=", v) }
  end

  # The attributes that make up the structure.
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

  def defaults
    self.class.defaults
  end
end

require 'structure/ext/active_support' if defined?(Rails)
