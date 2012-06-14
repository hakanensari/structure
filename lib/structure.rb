begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a data structure.
class Structure
  class << self
    # Internal: Returns the Hash attribute definitions of the structure.
    attr_accessor :blueprint

    # Builds a structure out of its JSON representation.
    #
    # hsh - A JSON representation translated to a Hash.
    #
    # Returns a Structure.
    def json_create(hsh)
      hsh.delete 'json_class'
      new hsh
    end

    # Defines an attribute.
    #
    # key  - The String-like key of the attribute.
    # type - The Class to which the value should be coerced into or a
    #        Proc that formats the value (default: nil).
    # opts - The Hash options to create the attribute with (default: {}).
    #        :default - The default Object value.
    #
    # Returns nothing.
    def attribute(key, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      @blueprint[key] = { :type => args.shift, :default => opts[:default] }
    end

    # Syntactic sugar to define a collection.
    #
    # key - The String-like key of the attribute.
    #
    # Returns nothing.
    def many(key)
      attribute key, Array, :default => []
    end

    # Syntactic sugar to define an attribute that stands in for another
    # structure.
    #
    # key - The String-like key of the attribute.
    #
    # Returns nothing.
    def one(key)
      attribute key, lambda { |v| Structure.new v }, :default => Structure.new
    end

    private

    def inherited(subclass)
      subclass.blueprint = blueprint.dup
    end
  end

  @blueprint = {}

  # Returns the Hash attributes of the structure.
  attr :attributes

  alias to_hash attributes

  # Creates a new structure.
  #
  # hsh - A Hash of keys and values to populate the structure (default: {}).
  def initialize(hsh = {})
    @attributes = self.class.blueprint.inject({}) do |a, (k, v)|
      default = if v[:default].is_a? Proc
                  v[:default].call
                else
                  v[:default].dup rescue v[:default]
                end
      a.merge new_attribute(k, v[:type]) => default
    end

    marshal_load hsh
  end

  # Deletes an attribute.
  #
  # key - The String-like key of the attribute.
  #
  # Returns the Object value of the deleted attribute.
  def delete_attribute(key)
    key = key.to_sym
    class << self; self; end.class_eval do
      [key, "#{key}="].each { |m| remove_method m }
    end

    @attributes.delete key
  end

  # Provides marshalling support for use by the Marshal library.
  #
  # Returns a Hash of the keys and values of the structure.
  def marshal_dump
    @attributes.inject({}) do |a, (k, v)|
      a.merge k => recursively_dump(v)
    end
  end

  # Provides marshalling support for use by the Marshal library.
  #
  # hsh - A Hash-like set of keys and values to populate the structure.
  def marshal_load(hsh)
    hsh.to_hash.each do |k, v|
      self.send "#{new_attribute(k)}=", v
    end
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

  private

  def initialize_copy(orig)
    super
    @attributes = @attributes.dup
  end

  def method_missing(mth, *args)
    name = mth.to_s
    if name.chomp!('=') && mth != :[]=
      modifiable[new_attribute(name)] = recursively_load args.first
    elsif args.length == 0
      @attributes[new_attribute(mth)]
    else
      super
    end
  end

  def modifiable
    if frozen?
      raise RuntimeError, "can't modify frozen #{self.class}", caller(3)
    end

    @attributes
  end

  def new_attribute(key, type = nil)
    key = key.to_sym
    unless self.respond_to? key
      class << self; self; end.class_eval do
        define_method(key) { @attributes[key] }

        assignment =
          case type
          when nil
            lambda { |v| modifiable[key] = recursively_load v }
          when Proc
            lambda { |v| modifiable[key] = type.call v }
          when Class
            mth = type.to_s.to_sym
            if Kernel.respond_to? mth
              lambda { |v|
                modifiable[key] = v.nil? ? nil : Kernel.send(mth, v)
              }
            else
              lambda { |v|
                modifiable[key] =
                  if v.nil? || v.is_a?(type)
                    v
                  else
                    raise TypeError, "#{v} isn't a #{type}"
                  end
              }
            end
          else
            raise TypeError, "#{type} isn't a valid type"
          end

        define_method "#{key}=", assignment
      end
    end

    key
  end

  def recursively_dump(val)
    if val.respond_to? :marshal_dump
       val.marshal_dump
     elsif val.is_a? Array
       val.map { |v| recursively_dump v }
     else
       val
     end
  end

  def recursively_load(val)
    case val
    when Hash
      self.class.new val
    when Array
      val.map { |v| recursively_load v }
    else
      val
    end
  end
end
