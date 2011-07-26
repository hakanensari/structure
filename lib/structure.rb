begin
  ::JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Fabricate a +Boolean+ class.
unless defined? Boolean
  module Boolean; end
  [TrueClass, FalseClass].each { |klass| klass.send :include, Boolean }
end

# Structure is a Ruby module that turns a class into a key/value container.
#
#    class Person
#      include Structure
#
#      attribute :name
#      attribute :age, Integer
#    end
#
#    person = Person.new(:name => "John")
#    person.name
#    => "John"
#
module Structure
  include Enumerable

  # Structure supports the following types.
  TYPES = [Array, Boolean, Float, Hash, Integer, String, Structure]

  module ClassMethods
    # Defines an attribute that represents an array of objects, possibly
    # structures.
    def embeds_many(key)
      attribute key, Array, :default => []
    end

    # Defines an attribute that represents another structure.
    def embeds_one(key)
      attribute key, Structure
    end

    # Builds a structure out of its JSON representation.
    def json_create(object)
      object.delete 'json_class'
      new object
    end

    # Defines an attribute.
    #
    # Takes a key, an optional type, and an optional hash of options.
    #
    # The type can be +Array+, +Boolean+, +Float+, +Hash+, +Integer+, +String+,
    # or +Structure+. If none is specified, this defaults to String.
    #
    # Available options are:
    #
    # * +:default+, which sets the default value for the attribute.
    def attribute(key, *args)
      key     = key.to_sym
      options = args.last.is_a?(Hash) ?  args.pop : {}
      type    = args.shift || String
      default = options[:default]

      if method_defined? key
        raise NameError, "#{key} is already defined"
      end

      if TYPES.include?(type) && (default.nil? || default.is_a?(type))
        default_attributes[key] = default
      else
        msg = "#{default} is not a#{'n' if type.to_s.match(/^[AI]/)} #{type}"
        raise TypeError, msg
      end

      module_eval do
        # Define a closure that typecasts value.
        typecast =
          if type == Boolean
            lambda do |value|
              case value
              when Boolean
                value
              when String
                value !~ /0|false/i
              when Integer
                value != 0
              else
                !!value
              end
            end
          elsif [Hash, Structure].include? type
            # Don't bother with typecasting attributes of type +Hash+ or
            # +Structure+.
            lambda do |value|
              unless value.is_a? type
                raise TypeError, "#{value} is not a #{type}"
              end
              value
            end
          else
            lambda { |value| Kernel.send(type.to_s, value) }
          end

        # Define attribute accessors.
        define_method(key) { @attributes[key] }

        define_method("#{key}=") do |value|
          @attributes[key] = value.nil? ? nil : typecast.call(value)
        end

        # Define a method to check for presence.
        unless type == Array
          define_method("#{key}?") { !!@attributes[key] }
        end
      end
    end

    # Returns a hash of all attributes with default values.
    def default_attributes
      @default_attributes ||= {}
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Creates a new structure.
  #
  # A hash, if provided, will seed its attributes.
  def initialize(hash = {})
    @attributes = {}
    self.class.default_attributes.each do |key, value|
      @attributes[key] = value.is_a?(Array) ? value.dup : value
    end

    hash.each { |key, value| self.send("#{key}=", value) }
  end

  # A hash that stores the attributes of the structure.
  attr_reader :attributes

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
    @attributes.each { |value| block.call(value) }
  end

  # Returns a JSON representation of the structure.
  def to_json(*args)
    klass = self.class.name
    { JSON.create_id => klass }.
      merge(@attributes).
      to_json(*args)
  end

  # Compares this object with another object for equality. A Structure is equal
  # to the other object when latter is of the same class and the two objects'
  # attributes are the same.
  def ==(other)
    other.is_a?(self.class) && @attributes == other.attributes
  end
end
