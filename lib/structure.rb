begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a key/value container.
class Structure
  # Builds a structure out of a JSON representation.
  #
  # @param [Hash] hsh a JSON representation translated to a hash
  # @return [Structure] a structure
  def self.json_create(hsh)
    hsh.delete('json_class')
    new(hsh)
  end

  # Creates a new structure.
  #
  # @param [Hash] hsh an optional hash to populate fields
  def initialize(hsh = {})
    @table = {}
    marshal_load(hsh)
  end

  # Deletes a field.
  #
  # @param [#to_sym] key
  # @return [Object] the value of the deleted field
  def delete_field(key)
    key = key.to_sym
    class << self; self; end.class_eval do
      [key, "#{key}="].each { |m| remove_method m }
    end

    @table.delete key
  end

  # Provides marshalling support for use by the Marshal library.
  #
  # @return [Hash] a hash of the keys and values of the structure
  def marshal_dump
    @table.inject({}) do |a, (k, v)|
      a.merge k => if v.respond_to? :marshal_dump
                     v.marshal_dump
                   elsif v.is_a? Array
                     v.map { |v| v.marshal_dump }
                   else
                     v
                   end
    end
  end

  # Provides marshalling support for use by the Marshal library.
  #
  # @param [Hash] hsh a hash of keys and values to populate the
  # structure
  def marshal_load(hsh)
    hsh.each do |k, v|
      self.send("#{new_field(k)}=", recursively_marshal_load(v))
    end
  end

  # @return [String] a JSON representation of the structure
  def to_json(*args)
    { JSON.create_id => self.class.name }.
      merge(marshal_dump).
      to_json(*args)
  end

  # @return [Boolean] whether the object and +other+ are equal
  def ==(other)
    other.is_a?(Structure) && @table == other.table
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

      { JSON.create_id => self.class.name }.
        merge(subset)
    end
  end

  protected

  attr :table

  private

  def initialize_copy(orig)
    super
    @table = @table.dup
  end

  def method_missing(mth, *args)
    name = mth.to_s
    len = args.length
    if name.chomp!('=') && mth != :[]=
      modifiable[new_field(name)] = args.first
    elsif len == 0
      @table[new_field(mth)]
    else
      super
    end
  end

  def modifiable
    begin
      @modifiable = true
    rescue
      raise TypeError, "can't modify frozen #{self.class}", caller(3)
    end

    @table
  end

  def new_field(name)
    name = name.to_sym
    unless self.respond_to?(name)
      class << self; self; end.class_eval do
        define_method(name) { @table[name] }
        define_method("#{name}=") { |val| modifiable[name] = val }
      end
    end

    name
  end

  def recursively_marshal_load(val)
    case val
    when Hash
      self.class.new(val)
    when Array
      val.map { |v| recursively_marshal_load(v) }
    else
      val
    end
  end
end
