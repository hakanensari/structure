# External dependencies.
require 'double'

# Standard library dependencies.
require 'forwardable'

# Internal dependencies.
require 'structure/blueprint'
require 'structure/coercion'

# Load the default JSON library if nothing else is loaded.
begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a Hash-like data structure.
#
# An anonymous Structure resembles an OpenStruct, with the added benefit of
# being recursive.
#
# A named Structure allows the possibility to define attributes on the class
# level and coerce their data types.
class Structure
  extend Double
  extend Forwardable
  include Enumerable

  class << self
    # Defines an attribute on the class level.
    #
    # name - The Symbol name of the attribute.
    # type - The Class to which the value should be coerced into or a
    #        Proc that formats the value (default: nil).
    # opts - The Hash options to define the attribute with (default: {}).
    #        :default - The default value.
    #
    # Returns nothing.
    def attribute(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      make_accessible name, Coercion.build(args.first)
      blueprint.add name, opts[:default]
    end

    # A shorthand for `attribute`.
    alias key attribute

    # Syntactic sugar to define a collection.
    #
    # key - The String-like key of the attribute.
    #
    # Returns nothing.
    def many(key, klass = Structure)
      attribute key, ->(a) { Array(a).map { |v| klass.new v } }, default: []
    end

    # Syntactic sugar to define an attribute that stands in for another
    # structure.
    #
    # key - The String-like key of the attribute.
    #
    # Returns nothing.
    def one(key, klass = Structure)
      attribute key, ->(v) { klass.new v if v }
    end

    # Internal: Returns a Blueprint of default values.
    attr_accessor :blueprint

    # Internal: Builds a structure out of a JSON representation.
    #
    # hsh - A Hash translation of a JSON representation.
    #
    # Returns a Structure.
    def json_create(hsh)
      hsh.delete 'json_class'
      new hsh
    end

    private

    def inherited(subclass)
      subclass.blueprint = blueprint.dup
    end

    def make_accessible(key, coercion)
      define_method(key)       { attributes[key] }
      define_method("#{key}=") { |v| modifiable[key] = coercion[v] }
    end
  end

  @blueprint = Blueprint.new

  # Returns the Hash attributes of the structure.
  attr :attributes

  def_delegator :@attributes, :each

  # Creates a new structure.
  #
  # hsh - A Hash of keys and values to populate the structure (default: {}).
  def initialize(hsh = {})
    @attributes = {}

    blueprint
      .merge(hsh.reduce({}) { |a, (k, v)| a.merge k.to_sym => v })
      .each { |k, v| self.send "#{new_attribute(k)}=", v }
  end

  # Gets an attribute.
  #
  # key - The Symbol-like name of the attribute.
  #
  # Returns the value of the attribute.
  def [](key)
    self.send key
  end

  # Sets an attribute.
  #
  # key - The Symbol-like name of the attribute.
  # val - The value of the attribute.
  #
  # Returns nothing.
  def []=(key, val)
    self.send "#{key}=", val
  end

  # Returns a String JSON representation of the structure.
  def to_json(*args)
    { JSON.create_id => self.class.name }.
      merge(marshal_dump).
      to_json *args
  end

  # Compares the object to another.
  #
  # other - Another Object.
  #
  # Returns true or false.
  def ==(other)
    other.is_a?(Structure) && @attributes == other.attributes
  end

  if defined? ActiveSupport
    def as_json(options = nil)
      subset = if options
        if only = options[:only]
          marshal_dump.slice(*Array.wrap(only))
        elsif except = options[:except]
          marshal_dump.except(*Array.wrap(except))
        else
          marshal_dump
        end
      else
        marshal_dump
      end

      { JSON.create_id => self.class.name }.merge subset
    end
  end

  # Internal: Returns the Hash blueprint.
  def blueprint
    self.class.blueprint.to_h
  end

  # Internal: Provides marshalling support for use by the Marshal library.
  #
  # Returns a Hash of the keys and values of the structure.
  def marshal_dump
    dump = ->(val) do
      if val.respond_to? :marshal_dump
        val.marshal_dump
      elsif val.is_a? Array
        val.map { |v| dump[v] }
      else
        val
      end
    end

    attributes.reduce({}) { |a, (k, v)| a.merge k => dump[v] }
  end

  # Internal: Provides marshalling support for use by the Marshal library.
  #
  # hsh - A Hash-like set of keys and values to populate the structure.
  #
  # Returns nothing.
  def marshal_load(hsh)
    initialize hsh
  end

  private

  def initialize_copy(orig)
    super
    @attributes = @attributes.dup
  end

  def method_missing(mth, *args)
    len = args.length
    if mth[-1] == '='
      if methods.include? get = mth.to_s.chop.to_sym
        raise ArgumentError, "#{get} clashes with an existing method name"
      end
      if len != 1
        raise ArgumentError, "wrong number of arguments (#{len} for 1)"
      end
      new_attribute get
      self.send mth, args.first
    elsif len == 0
      @attributes[new_attribute mth]
    else
      super
    end
  end

  def modifiable
    if frozen?
      raise RuntimeError, "can't modify frozen #{self.class}"
    end

    @attributes
  end

  def new_attribute(key)
    unless methods.include? key
      (class << self; self; end).class_eval do
        make_accessible key, Coercion.build
      end
    end

    key
  end
end
