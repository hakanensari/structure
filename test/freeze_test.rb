require_relative 'helper'

class FreezeTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new name: 'John'
    @person.freeze
  end

  def test_change_existing_attribute
    assert_raises(RuntimeError) { @person.name = 'Jane' }
  end

  def test_add_new_attribute
    assert_raises(RuntimeError) { @person.age = 18 }
  end

  def test_change_clone
    clone = @person.clone
    assert_raises(RuntimeError) { clone.name = 'Jane' }
  end

  def test_change_dup
    dup = @person.dup
    dup.name = 'Jane'
    assert_equal 'Jane', dup.name
  end
end
