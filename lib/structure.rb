require 'json'

# A better struct.
class Structure

  # Mix in the Enumerable module.
  include Enumerable

  @@keys = []

  # Defines an attribute key.
  #
  # Takes a name and an optional hash of options. Available options are:
  #
  # * :type, which can be Integer, Float, String, and Array.
  #
  #    class Book
  #      key :title,   :type => String
  #      key :authors, :type => Array
  #    end
  #
  def self.key(name, options={})
    if method_defined?(name)
      raise NameError, "#{name} is already defined"
    end

    name = name.to_sym
    type = options[:type]
    @@keys << name

    module_eval do

      # Define a getter.
      define_method(name) { @attributes[name] }

      # Define a setter. The setter will optionally typecast.
      define_method("#{name}=") do |value|
        modifiable[name] =
          if type && value
            Kernel.send(type.to_s, value)
          else
            value
          end
      end
    end
  end

  # Creates a new structure.
  #
  # Optionally, populates the structure with a hash of attributes. Otherwise,
  # all values default to nil.
  def initialize(seed = {})
    @attributes =
      @@keys.inject({}) do |attributes, name|
        attributes[name] = nil
        attributes
      end

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

  def modifiable
    begin
      @modifiable = true
    rescue
      raise TypeError, "can't modify frozen #{self.class}", caller(3)
    end
    @attributes
  end
end
