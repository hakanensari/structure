# frozen_string_literal: true

require_relative 'helper'
require 'structure'

class StructureTest < Minitest::Test
  def setup
    @klass = Class.new do
      include Structure
    end
  end

  def test_class_level_attribute_names
    @klass.attribute(:key) {}
    assert_equal ['key'], @klass.attribute_names
  end

  def test_instance_level_attribute_names
    @klass.attribute(:key) {}
    assert_equal ['key'], @klass.new.attribute_names
  end

  def test_an_attribute
    @klass.attribute(:key) { 'value' }
    assert_equal 'value', @klass.new.key
  end

  def test_attributes
    @klass.attribute(:key) { 'value' }
    assert_equal({ 'key' => 'value' }, @klass.new.attributes)
  end

  def test_to_h
    @klass.attribute(:key) { 'value' }
    assert_equal({ 'key' => 'value' }, @klass.new.to_h)
  end

  def test_to_s
    @klass.attribute(:key) { 'value' }
    assert_equal '#<? key="value">', @klass.new.to_s
  end

  def test_to_s_with_named_class
    @klass.attribute(:key) { 'value' }
    class << @klass
      define_method(:name) { 'Foo' }
    end
    assert_equal '#<Foo key="value">', @klass.new.to_s
  end

  def test_inspect
    @klass.attribute(:key) { 'value' }
    assert_equal @klass.new.to_s, @klass.new.inspect
  end

  def test_inspect_with_custom_to_s_defined
    @klass.attribute(:key) { 'value' }
    @klass.send(:define_method, :to_s) { '123' }
    assert_equal '#<? 123>', @klass.new.inspect
  end

  def test_memoization
    @klass.attribute(:key) { rand }
    instance = @klass.new
    assert_equal instance.key, instance.key
    refute_equal @klass.new.key, instance.key
  end

  def test_memoization_with_nil_value
    @klass.attribute(:key) { (@values ||= [rand(80), nil]).pop }
    instance = @klass.new
    2.times { assert_nil instance.key }
  end

  def test_subclassing_has_no_side_effects
    subclass = Class.new(@klass) do
      attribute(:key) {}
    end
    assert_includes subclass.attribute_names, 'key'
    refute_includes @klass.attribute_names, 'key'
  end

  def test_equality
    @klass.attribute(:key) { 'value' }
    assert_equal @klass.new, @klass.new
    assert @klass.new.eql?(@klass.new)
    subclass = Class.new(@klass)
    assert_equal @klass.new, @klass.new
    refute @klass.new.eql?(subclass.new)
  end

  def test_equality_with_comparison
    assert @klass.new == @klass.new
    @klass.send(:define_method, :<=>) { |_| 1 }
    refute @klass.new == @klass.new
  end

  def test_predicate
    @klass.attribute(:key?) { true }
    assert @klass.new.key
    assert @klass.new.key?
  end

  def test_thread_safety
    @klass.attribute(:key) { rand.tap { |value| sleep value } }
    instance = @klass.new
    threads = 10.times.map do
      Thread.new { Thread.current[:key] = instance.key }
    end
    values = threads.map { |thread| thread.join[:key] }

    assert_equal 1, values.uniq.count
  end

  def test_no_deadlock
    @klass.attribute(:foo) { 'value' }
    @klass.attribute(:bar) { foo }
    instance = @klass.new
    assert_equal instance.foo, instance.bar
  end

  def test_freeze
    @klass.attribute(:key) { rand }
    instance = @klass.new
    instance.freeze
    assert instance.key
  end

  def test_including_in_module
    mod = Module.new do
      include Structure
    end
    klass = Class.new do
      include mod
      attribute(:key) {}
    end
    assert_equal ['key'], klass.new.attribute_names
  end
end
