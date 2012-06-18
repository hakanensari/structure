require_relative 'helper'

class RecursionTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new
    @hsh = { name: 'Jane' }
  end

  def test_hash
    @person = Structure.new
    @person.friend = @hsh
    assert_equal 'Jane', @person.friend.name
  end

  def test_array
    @person.friends = [@hsh]
    assert_equal 'Jane', @person.friends.first.name
  end
end
