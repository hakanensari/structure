require_relative 'helper'

class CloneAndDupTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
  end

  def test_clone
    clone = @person.clone
    assert_equal 'John', clone.name
    clone.age = 18
    assert_nil @person.age
  end

  def test_dup
    dup = @person.dup
    assert_equal 'John', dup.name
    dup.age = 18
    assert_nil @person.age
  end
end
