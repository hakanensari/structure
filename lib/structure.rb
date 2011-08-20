begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# = Structure
#
# +Structure+ is a typecast, nestable key/value container.
#
#    class Person < Structure
#      key  :name
#      many :friends, Person
#    end
#
class Structure
  include Enumerable

  autoload :Boolean,    'certainty'
  autoload :Collection, 'structure/collection'
  autoload :Static,     'structure/static'

  module Type; end

  # An attribute may be of the following data types.
  TYPES = [Array, Boolean, Float, Hash, Integer, String, Structure]

  class << self
    def const_missing(class_name)
      Object.const_set class_name, Class.new(Structure)
    end

    # Defines an attribute that represents a collection.
    def many(name, klass)
      collection = Collection.new(klass)
      key(name, collection, :default => collection.new)
    end

    # Defines an attribute that represents another structure.
    def one(name, klass)
      key(name, klass)

      define_method("create_#{name}") do |*args|
        self.send("#{name}=", klass.new(*args))
      end
    end

    # Builds a Ruby object out of the JSON representation of a
    # structure.
    def json_create(object)
      object.delete 'json_class'
      new object
    end

    # Defines an attribute.
    #
    # Takes a name, an optional type, and an optional hash of options.
    #
    # If nothing is specified, type defaults to +String+.
    #
    # Available options are:
    #
    # * +:default+, which sets the default value for the attribute. If
    #   no default value is specified, it defaults to +nil+.
    def key(name, *args)
      name    = name.to_sym
      options = args.last.is_a?(Hash) ?  args.pop : {}
      type    = args.shift || String
      default = options[:default]

      if method_defined? name
        raise NameError, "#{name} is already defined"
      end

      if (type.ancestors & TYPES).empty?
        raise TypeError, "#{type} isn't a valid type"
      end

      if default.nil? || default.is_a?(type)
        defaults[name] = default
      else
        raise TypeError, "#{default} isn't a #{type}"
      end

      module_eval do
        # Define attribute accessors.
        define_method(name) { @attributes[name] }

        define_method("#{name}=") do |value|
          @attributes[name] =
            if value.is_a?(type) || value.nil?
              value
            elsif Kernel.respond_to? type.to_s
              Kernel.send(type.to_s, value)
            else
              Type.send(type.to_s, value)
            end
        end
      end
    end

    # Returns a hash of all attributes with default values.
    def defaults
      @defaults ||= {}
    end
  end

  # Creates a new structure.
  #
  # A hash, if provided, will seed its attributes.
  def initialize(hash = {})
    @attributes = self.class.defaults.inject({}) do |a, (k, v)|
      a[k] = v.is_a?(Array) ? v.dup : v
      a
    end

    method_name = self.class.name || self.class.to_s
    (class << Type; self; end).send(:define_method, method_name) do |arg|
      case arg
      when self.class
        arg
      else
        new arg
      end
    end

    hash.each { |k, v| self.send("#{k}=", v) }
  end

  # The attributes that make up the structure.
  attr :attributes

  # Returns a Rails-friendly JSON representation of the structure.
  def as_json(options = nil)
    subset = if options
      if attrs = options[:only]
        @attributes.slice(*Array.wrap(attrs))
      elsif attrs = options[:except]
        @attributes.except(*Array.wrap(attrs))
      else
        @attributes.dup
      end
    else
      @attributes.dup
    end

    klass = self.class.name
    { JSON.create_id => klass }.
      merge(subset)
  end

  # Calls block once for each attribute in the structure, passing that
  # attribute as a parameter.
  def each(&block)
    @attributes.each { |v| block.call(v) }
  end

  # Returns a hash representation of the structure.
  def to_hash
    @attributes.inject({}) do |a, (k, v)|
      a[k] =
        if v.respond_to?(:to_hash)
          v.to_hash
        elsif v.is_a? Array
          v.map { |e| e.respond_to?(:to_hash) ? e.to_hash : e }
        else
          v
        end
      a
    end
  end

  # Returns a JSON representation of the structure.
  def to_json(*args)
    klass = self.class.name
    { JSON.create_id => klass }.
      merge(@attributes).
      to_json(*args)
  end

  # Compares this object with another object for equality. A Structure
  # is equal to the other object when latter is of the same class and
  # the two objects' attributes are the same.
  def ==(other)
    other.is_a?(self.class) && @attributes == other.attributes
  end
end
