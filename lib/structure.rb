class Structure
  def initialize(hsh = {})
    @table = hsh.inject({}) { |a, (k, v)| a.merge new_field(k) => v }
  end

  def delete_field(name)
    name = name.to_sym
    @table.delete name
    class << self; self; end.class_eval do
      [name, "#{name}="].each { |m| remove_method m }
    end
  end

  def marshal_dump
    @table.inject({}) { |a, (k, v)| a.merge k => v }
  end

  def marshal_load(hsh)
    (@table = hsh).each_key { |key| new_field(key) }
  end

  def ==(other)
    other.is_a?(Structure) && @table == other.table
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
      if len != 1
        raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
      end
      modifiable[new_field(name)] = args.first
    elsif len == 0 && @table.has_key?(mth)
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
end
