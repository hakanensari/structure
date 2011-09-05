begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

require 'structure/wrapper'

# A structure is a nestable key/value container.
#
#    class Person < Structure
#      key  :name
#      key  :age, Integer
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

    # Builds a structure out of the JSON representation of a
    # structure.
    def json_create(hsh)
      hsh.delete 'json_class'
      new hsh
    end

    # Defines an attribute.
    #
    # Takes a name and, optionally, a type and options hash.
    #
    # The type should be a Ruby class.
    #
    # Available options are:
    #
    # * +:default+, which specifies a default value for the attribute.
    def key(name, *args)
      name    = name.to_sym
      options = args.last.is_a?(Hash) ?  args.pop : {}
      type    = args.shift
      default = options[:default]

      if method_defined?(name)
        raise NameError, "#{name} is taken"
      end

      if default.nil? || type.nil? || default.is_a?(type)
        defaults[name] = default
      else
        raise TypeError, "#{default} isn't a #{type}"
      end

      define_method(name) { attributes[name] }

      if type.nil?
        define_method("#{name}=") { |val| attributes[name] = val }
      elsif !type.is_a?(Wrapper)
        define_method("#{name}=") do |val|
          attributes[name] =
            if val.nil? || val.is_a?(type)
              val
            elsif Kernel.respond_to?(type.to_s)
              Kernel.send(type.to_s, val)
            else
              raise TypeError, "#{val} isn't a #{type}"
            end
        end
      end
    end

    # A shorthand that defines an attribute that is an array.
    def many(name)
      key name, Array, :default => []
    end

    private

    def const_missing(name)
      Wrapper.new(name)
    end
  end

  # Creates a new structure.
  #
  # A hash, if provided, will seed the attributes.
  def initialize(hsh = {})
    @attributes = self.class.defaults.inject({}) do |a, (k, v)|
      a[k] = v.is_a?(Array) ? v.dup : v
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
        if v.respond_to? :to_hash
          v.to_hash
        elsif v.is_a? Array
          v.map { |e| e.respond_to?(:to_hash) ? e.to_hash : e }
        else
          v
        end

      a
    end
  end

  # Converts structure to a JSON representation.
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

require 'structure/rails' if defined?(Rails)
