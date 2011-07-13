# Ruby doesn't have a Boolean class, so let's feign one.
unless Object.const_defined?(:Boolean)
  module Boolean; end
  class TrueClass; include Boolean; end
  class FalseClass; include Boolean; end
end

# A key/value container for modeling ephemeral data.
class Structure
  include Enumerable

  TYPES = [Array, Boolean, Float, Hash, Integer, String, Structure]

  class << self
    # A shortcut to define an attribute that represents an array of other
    # objects, possibly structures.
    def embeds_many(name)
      key name, Array, :default => []
    end

    # A shortcut to define an attribute that represents another structure.
    def embeds_one(name)
      key name, Structure
    end

    # Defines an attribute key.
    #
    # Takes a name, an optional type, and an optional hash of options.
    #
    # The type can be Array, Boolean, Float, Hash, Integer, String, or
    # Structure. If none is specified, it defaults to String.
    #
    # Available options are:
    #
    # * :default, which sets the default value for the attribute.
    #
    #    class Book
    #      key :title
    #      key :authors, Array, :default => []
    #    end
    def key(name, *args)
      name = name.to_sym
      options = if args.last.is_a? Hash
                  args.pop
                else
                  {}
                end
      type = args.shift || String

      if method_defined?(name)
        raise NameError, "#{name} is already defined"
      end

      unless TYPES.include? type
        raise TypeError, "#{type} is not a valid type"
      end

      default = options[:default]
      unless default.nil? || default.is_a?(type)
        raise TypeError, "#{default} is not #{%w{AEIOU}.include?(type.to_s[0]) ? 'an' : 'a'} #{type}"
      end

      default_attributes[name] = default

      module_eval do

        # Define a proc to typecast value.
        typecast =
          if type == Boolean
            lambda do |value|
              case value
              when String
               value =~ /1|true/i
              when Integer
                value != 0
              else
               !!value
              end
            end
          elsif [Hash, Structure].include? type

            # Raise an exception rather than typecast if type is Hash or
            # Structure.
            lambda do |value|
              unless value.is_a? type
                raise TypeError, "#{value} is not a #{type}"
              end
              value
            end
          else
            lambda { |value| Kernel.send(type.to_s, value) }
          end

        # Define a getter.
        define_method(name) { @attributes[name] }

        # Define a setter.
        define_method("#{name}=") do |value|
          @attributes[name] = value.nil? ? nil : typecast.call(value)
        end

        # Define a "presence" (for lack of a better term) method
        define_method("#{name}?") { !!@attributes[name] }
      end
    end

    # Returns a hash of all attributes with default values.
    def default_attributes
      @default_attributes ||= {}
    end
  end

  # Creates a new structure.
  #
  # Optionally, seeds the structure with a hash of attributes.
  def initialize(seed = {})
    initialize_attributes
    seed.each { |key, value| self.send("#{key}=", value) }
  end

  # A hash of attributes.
  attr_reader :attributes

  def each(&block)
    @attributes.each { |value| block.call(value) }
  end

  # Returns an array populated with the attribute keys.
  def keys
    @attributes.keys
  end

  # Returns an array populated with the attribute values.
  def values
    @attributes.values
  end

  # Compares this object with another object for equality. A Structure is equal
  # to the other object when latter is also a Structure and the two objects'
  # attributes are equal.
  def ==(other)
    other.is_a?(Structure) && @attributes == other.attributes
  end

  private

  def initialize_attributes
    @attributes = {}
    self.class.default_attributes.each do |key, value|
      @attributes[key] = value.is_a?(Array) ? value.dup : value
    end
  end
end
