require_relative 'helper'

class ElementTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
  end

  def test_element_get_string
    assert_equal 'John', @person['name']
  end

  def test_element_get_symbol
    assert_equal 'John', @person[:name]
  end

  def test_element_get_nonexisting_attribute
    assert_nil @person[:age]
  end

  def test_element_set_string
    @person['name'] = 'John'
    assert_equal 'John', @person.name
  end

  def test_element_set_symbol
    @person[:name] = 'John'
    assert_equal 'John', @person.name
  end

  def test_element_set_nonexisting_attribute
    @person[:age] = 18
    assert_equal 18, @person.age
  end
end
