require_relative 'helper'
require 'pry'

class MethodMissingTest < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new
  end

  def test_new_accessor
    @person.age = 18
    assert_respond_to @person, :age
    assert_respond_to @person, :age=
    assert_equal 18, @person.age
  end

  def test_getter_with_arg_error
    assert_raises(NoMethodError) { @person.age(18) }
    assert_nil @person.age
  end

  def test_setter_with_arg_error
    assert_raises(ArgumentError) { @person.send :age= }
    assert_nil @person.age
  end

  def test_freeze
    @person.freeze
    assert_raises(RuntimeError) { @person.age = 18 }
  end

  def test_existing_method
    @person.instance_eval { def age; end }
    assert_raises ArgumentError do
      @person.age = 18
    end
  end
end
