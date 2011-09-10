begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a nestable, typed key/value container.
#
#    class Person < Structure
#      key  :name
#      many :friends
#    end
#
class Structure
  include Enumerable

  # A namespaced basic object.
  #
  # If running a legacy Ruby version, we either quote Builder's or
  # fabricate one ourselves.
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

  # A double that stands in for a yet-to-be-defined class. Otherwise
  # known as "lazy evaluation."
  #
  # Idea lifted from:
  # http://github.com/soveran/ohm/
  class Double < BasicObject
    def initialize(name)
      @name = name
    end

    def to_s
      @name.to_s
    end

    def method_missing(mth, *args, &block)
      @unwrapped ? super : @unwrapped = true
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

    # Lazy-eval undefined constants, typically other structures,
    # assuming they will be defined later in the text.
    def const_missing(name)
      Double.new(name)
    end; private :const_missing

    def inherited(child)
      child.class_eval do
        def initialize(hsh = {})
          @attributes = defaults.inject({}) do |a, (k, v)|
            a[k] = v.dup rescue v
            a
          end

          hsh.each { |k, v| self.send("#{k}=", v) }
        end
      end
    end; private :inherited
  end

  def initialize
    raise
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

  def defaults
    self.class.defaults
  end; private :defaults
end

require 'structure/ext/active_support' if defined?(Rails)
