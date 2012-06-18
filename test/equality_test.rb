require_relative 'helper'

class EqualityTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
  end

  def test_self
    assert @person == @person
  end

  def test_same_attributes
    assert @person == Structure.new(name: 'John')
  end

  def test_inequality
    refute @person == 'foo'
    refute @person == Structure.new(name: 'Johnny')
    refute @person == Structure.new(name: 'John', age: 20)
  end
end
