# frozen_string_literal: true

require_relative 'helper'

class StructureTest < Minitest::Test
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

    assert_equal(%w[name], Person.attribute_names)
    assert_equal(%w[name age], subclass.attribute_names)

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
    klass = build_anonymous_class do
      def initialize(foo)
        @foo = foo
      end

      attribute(:bar) { @foo }
    end

    instance = klass.new(@person)
    assert_equal({ 'bar' => { 'name' => 'Jane' } }, instance.attributes)

    instance = klass.new([@person])
    assert_equal({ 'bar' => [{ 'name' => 'Jane' }] }, instance.attributes)
  end

  def test_attribute_returns_symbol
    assert_equal :foo, build_anonymous_class.send(:attribute, :foo) {}
  end

  def test_memoises_attributes
    assert_equal 'Jane', @person.name

    @person.instance_variable_set(:@data, name: 'John')
    assert_equal 'Jane', @person.name
  end

  def test_attributes_memoise_nil
    person = Person.new(name: nil)
    assert_nil person.name

    person.instance_variable_set(:@data, name: 'John')
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
    assert_match(/#<Class:\w+ .*>/, build_anonymous_class.new.to_s)
  end

  def test_truncates_long_arrays_when_pretty_inspecting
    klass = build_anonymous_class do
      attribute(:ary) { ['a'] }
    end
    assert_includes klass.new.inspect, 'ary=["a"]'

    klass = build_anonymous_class do
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
  end

  def test_thread_safety
    klass = Class.new do
      include Structure

      attribute :value do
        sleep rand
        rand
      end
    end

    object = klass.new
    threads = 10.times.map do
      Thread.new do
        Thread.current[:value] = object.value
      end
    end
    values = threads.map { |thread| thread.join[:value] }

    assert_equal 1, values.uniq.count
  end
end
