# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestRequiredOptional < Minitest::Test
  def test_required_attribute_must_be_present
    person = Structure.new do
      attribute(:name, String)
    end

    error = assert_raises(ArgumentError) do
      person.parse({})
    end

    assert_match(/missing keyword/, error.message)
    assert_match(/:name/, error.message)
  end

  def test_required_attribute_can_be_nil
    person = Structure.new do
      attribute(:name, String)
    end

    result = person.parse(name: nil)

    assert_nil(result.name)
  end

  def test_optional_attribute_can_be_missing
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    result = person.parse(name: "Alice")

    assert_equal("Alice", result.name)
    assert_nil(result.age)
  end

  def test_optional_attribute_can_be_present
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    result = person.parse(name: "Alice", age: 30)

    assert_equal("Alice", result.name)
    assert_equal(30, result.age)
  end

  def test_optional_attribute_can_be_nil
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    result = person.parse(name: "Alice", age: nil)

    assert_equal("Alice", result.name)
    assert_nil(result.age)
  end

  def test_optional_attribute_with_default
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer, default: 0)
    end

    result = person.parse(name: "Alice")

    assert_equal("Alice", result.name)
    assert_equal(0, result.age)
  end

  def test_multiple_missing_required_attributes
    person = Structure.new do
      attribute(:name, String)
      attribute(:age, Integer)
    end

    error = assert_raises(ArgumentError) do
      person.parse({})
    end

    assert_match(/missing keyword/, error.message)
  end

  def test_all_optional_attributes
    person = Structure.new do
      attribute?(:name, String)
      attribute?(:age, Integer)
    end

    result = person.parse({})

    assert_nil(result.name)
    assert_nil(result.age)
  end

  def test_new_with_optional_attributes_can_be_omitted
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    result = person.new(name: "Bob")

    assert_equal("Bob", result.name)
    assert_nil(result.age)
  end

  def test_new_with_optional_attributes_can_be_provided
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    result = person.new(name: "Alice", age: 30)

    assert_equal("Alice", result.name)
    assert_equal(30, result.age)
  end

  def test_new_missing_required_attribute
    person = Structure.new do
      attribute(:name, String)
      attribute?(:age, Integer)
    end

    error = assert_raises(ArgumentError) do
      person.new(age: 25)
    end

    assert_match(/missing keyword/, error.message)
    assert_match(/:name/, error.message)
  end

  def test_new_with_all_optional_attributes
    person = Structure.new do
      attribute?(:name, String)
      attribute?(:age, Integer)
    end

    result = person.new

    assert_nil(result.name)
    assert_nil(result.age)
  end
end
