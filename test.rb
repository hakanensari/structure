require 'minitest/autorun'
require 'minitest/pride'
require './structure'

Person = Class.new do
  include Structure

  def initialize(data)
    @data = data
  end

  attribute(:name) do
    @data.fetch(:name)
  end
end

class StructureTest < MiniTest::Unit::TestCase
  def setup
    @person = Person.new(name: 'Jane')
  end

  def test_both_class_and_instance_return_attribute_names
    assert_equal ['name'], Person.attribute_names
    assert_equal ['name'], Person.new(nil).attribute_names
  end

  def test_subclassing_does_not_have_side_effects
    subclass = Class.new(Person) do
      attribute :age do
        @data.fetch(:age)
      end
    end

    assert_equal(%w(name), Person.attribute_names)
    assert_equal(%w(name age), subclass.attribute_names)

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

  def test_returns_attributes_of_nested_structures
    klass = Class.new do
      include Structure
      attribute(:foo) { @foo }
      attr_writer :foo
    end

    instance = klass.new
    instance.foo = @person
    assert_equal({'foo' => {'name' => 'Jane'}}, instance.attributes)

    instance = klass.new
    instance.foo = [@person]
    assert_equal({'foo' => [{'name' => 'Jane'}]}, instance.attributes)
  end

  def test_attribute_returns_symbol
    assert_equal :foo, Class.new { include Structure }.send(:attribute, :foo) {}
  end

  def test_memoises_attributes
    assert_equal 'Jane', @person.name

    @person.instance_variable_set(:@data, { name: 'John' })
    assert_equal 'Jane', @person.name
  end

  def test_attributes_memoise_nil
    person = Person.new(name: nil)
    assert_nil person.name

    person.instance_variable_set(:@data, { name: 'John' })
    assert_nil person.name
  end

  def test_freezes_attributes
    assert @person.name.frozen?
  end

  def test_compares
    same = Person.new(name: 'Jane')
    assert @person == same
    assert @person.eql?(same)

    different = Person.new(name: 'John')
    refute @person == different

    refute @person == Object.new
  end

  def test_pretty_inspects
    assert_equal '#<Person name="Jane">', @person.inspect
    assert_equal @person.to_s, @person.inspect
    assert_match /#<Class:\w+ .*>/, build_anonymous_class.new.to_s
  end

  def test_truncates_long_arrays_when_pretty_inspecting
    klass = build_anonymous_class do
      attribute(:ary) { ['a'] }
    end
    assert_includes klass.new.inspect, 'ary=["a"]'

    klass.instance_eval do
      attribute(:ary) { ('a'..'z').to_a }
    end
    assert_includes klass.new.inspect, 'ary=["a", "b", "c"...]'
  end

  def test_predicate_methods
    klass = build_anonymous_class do
      attribute(:foo?) { true }
    end

    assert klass.new.foo
    assert klass.new.foo?

    object = klass.double.new(foo: true)
    assert object.foo?
    assert_equal object.foo, object.foo?
  end

  def test_casts_to_double
    person = Person.double.new('name' => 'Jane')
    assert_equal 'Jane', person.name
  end

  def test_defines_custom_methods_on_double
    double = build_anonymous_class.double do
      def foo
      end
    end

    assert_respond_to double.new, :foo
  end

  def test_double_inherits_public_methods
    mod = Module.new do
      def foo
      end
    end

    klass = build_anonymous_class do
      include mod

      def bar
      end
    end

    assert_respond_to klass.double.new, :foo
    assert_respond_to klass.double.new, :bar
  end

  def test_double_does_not_inherit_nonpublic_methods
    klass = build_anonymous_class do
      protected

      def foo
      end

      private

      def bar
      end
    end

    double = klass.double
    assert_raises(NoMethodError) { double.new.send(:foo) }
    assert_raises(NoMethodError) { double.new.send(:bar) }
  end

  private

  def build_anonymous_class(&blk)
    Class.new do
      include Structure

      class_eval(&blk) if block_given?
    end
  end
end
