# A better Ruby Struct.
class Structure
  include Enumerable

  # Ruby doesn't have a Boolean class, so let's feign one.
  unless Object.const_defined?(:Boolean)
    module ::Boolean; end
    class ::TrueClass; include Boolean; end
    class ::FalseClass; include Boolean; end
  end

  TYPES = [Array, Boolean, Float, Hash, Integer, String]

  # Defines an attribute key.
  #
  # Takes a name and an optional hash of options. Available options are:
  #
  # * :type, which can be Array, Boolean, Float, Integer, JSON, Pathname,
  # String, or URI. If not specified, type defaults to String.
  # * :default, which sets the default value for the attribute.
  #
  #    class Book
  #      key :title,   :type => String
  #      key :authors, :type => Array, :default => []
  #    end
  #
  def self.key(name, options={})
    name = name.to_sym
    if method_defined?(name)
      raise NameError, "#{name} is already defined"
    end

    type = options[:type] || String
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
             !(value =~ /false/i)
            else
             !!value
            end
          end
        elsif type == Hash
          lambda do |value|
            unless value.is_a? Hash
              raise TypeError, "#{value} is not a Hash"
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
        modifiable[name] = value.nil? ? nil : typecast.call(value)
      end
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

  def self.default_attributes
    @default_attributes ||= {}
  end

  def initialize_attributes
    @attributes =
      self.class.default_attributes.inject({}) do |attributes, (key, value)|
        attributes[key] = value
        attributes
      end
  end

  def modifiable
    begin
      @modifiable = true
    rescue
      raise TypeError, "can't modify frozen #{self.class}"
    end
    @attributes
  end
end
