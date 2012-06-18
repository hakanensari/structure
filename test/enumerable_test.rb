require_relative 'helper'

class EnumerableTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
  end

  def test_reduce
    hsh = @person.reduce({}) { |a, (k, v)| a.merge k => v }
    assert_equal({ name: 'John' }, hsh)
  end
end
