require 'minitest/autorun'
require 'minitest/pride'
require './structure'

Person = Struct.new(:res) do
  include Structure
  attribute(:name) { res.fetch(:name) }
end

class StructureTest < MiniTest::Unit::TestCase
  def setup
    @person = Person.new(name: 'Jane')
  end

  def test_class_returns_attribute_names
    assert_equal [:name], Person.attribute_names
  end

  def test_casts_itself_to_struct
    struct = Person.to_struct
    assert_equal 'Struct::Person', struct.name
    assert_equal 'Jane', struct.new(name: 'Jane').name
  end

  def test_cast_to_struct_only_once
    out, err = capture_io do
      2.times { Person.to_struct }
    end
    assert_empty err
  end

  def test_subclassing_does_not_have_side_effects
    subclass = Class.new(Person) do
      attribute(:age) { res.fetch(:age) }
    end
    obj = subclass.new(name: 'John', age: 18)
    assert_equal({ name: 'John', age: 18 }, obj.attributes)
  end

  def test_attributes
    assert_equal 'Jane', @person.name
  end

  def test_returns_attributes
    assert_equal({ name: 'Jane' }, @person.attributes)
    assert_equal @person.to_h, @person.attributes
  end

  def test_memoizes_attributes
    assert_equal 'Jane', @person.name
    @location.instance_variable_set(:@res, { name: 'John' })
    assert_equal 'Jane', @person.name
  end

  def test_compares
    @same = Person.new(name: 'Jane')
    assert @person == @same
    assert @person.eql?(@same)
    @different = Person.new(name: 'John')
    refute @person == @different
  end

  def test_pretty_inspects
    assert_equal '#<Person name="Jane">', @person.inspect
    assert_equal @person.to_s, @person.inspect
  end

  def test_truncates_long_arrays_when_pretty_inspecting
    klass = Class.new { include Structure }
    klass.attribute(:ary) { ['a'] }
    assert_includes klass.new.inspect, 'ary=["a"]'
    klass.attribute(:ary) { ('a'..'z').to_a }
    assert_includes klass.new.inspect, 'ary=["a", "b", "c"...]'
  end
end
