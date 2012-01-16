begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

# Structure is a key/value container. On the most basic level, it mirrors the
# functionality of OpenStruct:
#
#    require 'structure'
#
#    record = Structure.new
#    record.name    = "John Smith"
#    record.age     = 70
#    record.pension = 300
#
#    puts record.name    # -> "John Smith"
#    puts record.address # -> nil
#
# Build structures recursively:
#
#    hash = {
#     "name"       => "Australia",
#     "population" => "20000000",
#     "cities"     => [
#       {
#         "name"       => "Sydney",
#         "population" => "4100000"
#       },
#       {
#         "name"       => "Melbourne",
#         "population" => "4000000"
#       } ]
#     }
#
#     country = Structure.new(hash)
#     puts country.name              # -> "Australia"
#     puts country.cities.count      # -> 2
#     puts country.cities.first.name # -> "Sydney"
#
# Define optionally-typed fields in a structure:
#
#     class Price < Structure
#       field :cents, Integer
#       field :currency, String, :default => "USD"
#     end
#
#     hash = { "cents" => "100" }
#
#     price = Price.new(hash)
#     puts price.cents    # -> 100
#     puts price.currency # -> "USD"
#
# Alternatively, define a proc to cast or otherwise manipulate values and
# assign defaults:
#
#     class Product < Structure
#       field :sku, lambda(&:upcase)
#       field :created_at, String, :default => lambda { Time.now.to_s }
#     end
#
#     product = Product.new(:sku => 'foo-bar')
#     puts product.sku # -> "FOO-BAR"
#
# Structures are fully conversant in JSON, which is quite handy in the
# ephemeral landscape of APIs.
class Structure
  class << self
    # @private
    attr_accessor :blueprint

    # Builds a structure out of a JSON representation.
    # @param [Hash] hsh a JSON representation translated to a hash
    # @return [Structure] a structure
    def json_create(hsh)
      hsh.delete('json_class')
      new(hsh)
    end

    # Creates a field.
    # @overload field(key, opts = {})
    #   Creates a field.
    #   @param [#to_sym] key the name of the field
    #   @param [Hash] opts the options to create the field with
    #   @option opts [Object] :default the default value
    # @overload field(key, type, opts = {})
    #   Creates a typed field.
    #   @param [#to_sym] key the name of the field
    #   @param [Class, Proc] type the type to cast assigned values
    #   @param [Hash] opts the options to create the field with
    #   @option opts [Object] :default the default value
    def field(key, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      default = opts[:default]
      type = args.shift
      @blueprint[key] = { :type    => type,
                          :default => default }
    end

    alias key field

    # Syntactic sugar to create a typed field that defaults to an empty array.
    # @param key the name of the field
    def many(key)
      field(key, Array, :default => [])
    end

    private

    def inherited(child)
      child.blueprint = blueprint.dup
    end
  end

  @blueprint = {}

  # Creates a new structure.
  # @param [Hash] hsh an optional hash to populate fields
  def initialize(hsh = {})
    @table = blueprint.inject({}) do |a, (k, v)|
      default = if v[:default].is_a? Proc
                  v[:default].call
                else
                  v[:default].dup rescue v[:default]
                end

      a.merge new_field(k, v[:type]) => default
    end

    marshal_load(hsh)
  end

  # Deletes a field.
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
  # @return [Hash] a hash of the keys and values of the structure
  def marshal_dump
    @table.inject({}) do |a, (k, v)|
      a.merge k => recursively_dump(v)
    end
  end

  # Provides marshalling support for use by the Marshal library.
  # @param [Hash] hsh a hash of keys and values to populate the structure
  def marshal_load(hsh)
    hsh.each do |k, v|
      self.send("#{new_field(k)}=", v)
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

  protected

  attr :table

  private

  def blueprint
    self.class.blueprint
  end

  def initialize_copy(orig)
    super
    @table = @table.dup
  end

  def method_missing(mth, *args)
    name = mth.to_s
    len = args.length
    if name.chomp!('=') && mth != :[]=
      modifiable[new_field(name)] = recursively_load(args.first)
    elsif len == 0
      @table[new_field(mth)]
    else
      super
    end
  end

  def modifiable
    if frozen?
      raise RuntimeError, "can't modify frozen #{self.class}", caller(3)
    end

    @table
  end

  def new_field(key, type = nil)
    key = key.to_sym
    unless self.respond_to?(key)
      class << self; self; end.class_eval do
        define_method(key) { @table[key] }

        assignment =
          case type
          when nil
            lambda { |v| modifiable[key] = recursively_load(v) }
          when Proc
            lambda { |v| modifiable[key] = type.call(v) }
          when Class
            mth = type.to_s.to_sym
            if Kernel.respond_to?(mth)
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

        define_method("#{key}=", assignment)
      end
    end

    key
  end

  def recursively_dump(val)
    if val.respond_to? :marshal_dump
       val.marshal_dump
     elsif val.is_a? Array
       val.map { |v| recursively_dump(v) }
     else
       val
     end
  end

  def recursively_load(val)
    case val
    when Hash
      self.class.new(val)
    when Array
      val.map { |v| recursively_load(v) }
    else
      val
    end
  end

  if defined? ActiveSupport
    require 'structure/ext/active_support'
    include Ext::ActiveSupport
  end
end
