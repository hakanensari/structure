require_relative 'helper'

class MarshalTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
  end

  def test_dump
    assert_equal({ name: 'John' }, @person.marshal_dump)
  end

  def test_load
    @person.marshal_load age: 18
    assert_equal 18, @person.age
    assert_nil @person.name
  end

  def test_recursion
    friend = Structure.new name: 'Jane'
    @person.friend = friend
    assert_equal friend, @person.friend

    @person.friends = [friend]
    assert_equal friend, @person.friends.first

    hsh = @person.marshal_dump
    assert_equal 'Jane', hsh[:friend][:name]
    assert_equal 'Jane', hsh[:friends][0][:name]

    person = Structure.new
    person.marshal_load hsh
    assert_equal friend, person.friend
    assert_equal friend, person.friends.first
  end
end
