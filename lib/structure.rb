require 'forwardable'
begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# A structure is a nestable, typed key/value container.
#
#    class Person < Structure
#      key  :name, String
#      many :friends
#    end
#
class Structure
  extend Forwardable
  include Enumerable

  # Fabricate a Basic Object if not running Ruby version >= 1.9.
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

  # A wrapper for lazy-evaluating constants.
  #
  # The idea is lifted from:
  # http://github.com/soveran/ohm/
  class Wrapper < BasicObject
    def initialize(name)
      @name = name
    end

    # Delegates called method to wrapped class.
    def method_missing(mth, *args, &block)
      super if @unwrapped
      @unwrapped = true
      ::Kernel.const_get(@name).send(mth, *args, &block)
    ensure
      @unwrapped = false
    end; private :method_missing
  end

  class << self
    # Returns attribute keys and their default values.
    def defaults
      @defaults ||= {}
    end

    def inherited(child)
      child.def_delegator child, :defaults
    end

    # Builds a structure out of its JSON representation.
    def json_create(hsh)
      hsh.delete('json_class')
      new(hsh)
    end

    # Defines an attribute.
    #
    # Takes a name and optionally, a type and default value.
    def key(name, type = nil, default = nil)
      raise NameError, "#{name} is taken" if method_defined?(name)
      name = name.to_sym
      defaults[name] = default

      define_method(name) { attributes[name] }

      define_method("#{name}=") do |val|
        attributes[name] =
          # TODO: There must be a simpler way of saying this.
          if val.is_a?(Array) && type == Array
            val.dup
          elsif type.nil? || val.nil? || val.is_a?(type)
            val
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

    # Lazy-eval undefined constants, typically other structures,
    # assuming they will be defined later in the text.
    def const_missing(name)
      Wrapper.new(name)
    end; private :const_missing
  end

  # Creates a new structure.
  #
  # A hash, if provided, seeds the attributes.
  def initialize(hsh = {})
    @attributes = Hash.new
    defaults.merge(hsh).each { |k, v| self.send("#{k}=", v) }
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
end

require 'structure/active_support' if defined?(Rails)
