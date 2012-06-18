require_relative 'helper'

class Name < Structure
  key :first
  key :last
end

class Person < Structure
  one :name, Name
end

class TestOneToOne < MiniTest::Unit::TestCase
  def setup
    @person = Person.new name: { first: 'John', last: 'Doe' }
  end

  def test_initialize
    assert_equal 'John', @person.name.first
  end

  def test_write_hash
    @person.name = { first: 'Jane' }
    assert_equal 'Jane', @person.name.first
  end

  def test_write_nil
    @person.name = nil
    assert_nil @person.name
  end

  def test_kind
    assert_kind_of Name, @person.name
  end
end
