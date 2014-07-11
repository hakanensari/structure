require 'minitest/autorun'
require 'minitest/pride'
require './structure'

Person = Struct.new(:res) do
  include Structure
  attribute(:name) { res.fetch(:name) }
end

class StructureTest < MiniTest::Unit::TestCase
  def anon_class
    Class.new do
      include Structure
    end
  end

  def setup
    @person = Person.new(name: 'Jane')
  end

  def test_returns_attribute_names
    assert_equal ['name'], Person.attribute_names
    assert_equal ['name'], Person.new.attribute_names
  end

  def test_subclassing_does_not_have_side_effects
    subclass = Class.new(Person) do
      attribute(:age) { res.fetch(:age) }
    end
    obj = subclass.new(name: 'John', age: 18)
    assert_equal({ 'name' => 'John', 'age' => 18 }, obj.attributes)
  end

  def test_attributes
    assert_equal 'Jane', @person.name
  end

  def test_returns_attributes
    assert_equal({ 'name' => 'Jane' }, @person.attributes)
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
    assert_match /#<Class:\w+ .*>/, anon_class.new.to_s
  end

  def test_truncates_long_arrays_when_pretty_inspecting
    klass = anon_class
    klass.attribute(:ary) { ['a'] }
    assert_includes klass.new.inspect, 'ary=["a"]'
    klass.attribute(:ary) { ('a'..'z').to_a }
    assert_includes klass.new.inspect, 'ary=["a", "b", "c"...]'
  end

  def test_predicate_methods
    klass = anon_class
    klass.attribute(:foo?) { true }
    assert klass.new.foo
    assert klass.new.foo?
    object = klass.to_struct.new(foo: true)
    assert object.foo?
    assert_equal object.foo, object.foo?
  end

  def test_casts_to_struct
    struct = Person.to_struct
    assert_equal 'Struct::Person', struct.name
    assert_equal 'Jane', struct.new('name' => 'Jane').name
    Struct.send(:remove_const, :Person) # side effect
  end

  def test_defines_custom_methods_on_struct
    klass = anon_class
    struct = klass.to_struct do
      def foo; end
    end
    assert_respond_to struct.new, :foo
  end

  def test_includes_modules_in_struct
    m = Module.new do
      def foo; end
    end
    klass = Class.new do
      include Structure, m
    end
    struct = klass.to_struct
    assert_respond_to struct.new, :foo
    refute_includes struct, Structure
  end

  def test_the_included_edge_case!
    m = Module.new do
      def self.included(base)
        unless base.name.to_s.start_with?('Struct:')
          base.send(:include, Structure)
        end
      end
    end
    klass = Class.new do
      include m
    end
    refute_includes klass.to_struct, Structure
  end
end
