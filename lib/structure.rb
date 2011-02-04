require 'ostruct'

#
# Structure is a nested OpenStruct implementation.
#
class Structure < OpenStruct
  def initialize(source = {})
    @table = {}
    source.each do |k, v|
      @table[k.to_sym] = structure(v)
      new_ostruct_member(k)
    end
  end

  def method_missing(mid, *args) # :nodoc:
    mname = mid.id2name
    len = args.length
    if mname.chomp!('=')
      if len != 1
        raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
      end
      modifiable[new_ostruct_member(mname)] = structure(args[0])
    elsif len == 0
      @table[mid]
    else
      raise NoMethodError, "undefined method `#{mname}' for #{self}", caller(1)
    end
  end

  alias :to_hash :marshal_dump

  private

  def structure(o)
    case o
    when Hash
      self.class.new(o)
    when Array
      o.map { |o| structure(o) }
    else
      o
    end
  end
end
