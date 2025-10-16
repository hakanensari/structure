# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestNonNullable < Minitest::Test
  def test_required_non_nullable_with_nil_value
    person = Structure.new do
      attribute(:id, String, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse(id: nil)
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:id/, error.message)
  end

  def test_required_non_nullable_with_missing_key
    person = Structure.new do
      attribute(:id, String, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse({})
    end

    assert_match(/missing keyword/, error.message)
    assert_match(/:id/, error.message)
  end

  def test_required_non_nullable_with_valid_value
    person = Structure.new do
      attribute(:id, String, null: false)
    end

    result = person.parse(id: "123")

    assert_equal("123", result.id)
  end

  def test_optional_non_nullable_with_missing_key
    person = Structure.new do
      attribute?(:name, String, null: false)
    end

    result = person.parse({})

    assert_nil(result.name)
  end

  def test_optional_non_nullable_with_nil_value
    person = Structure.new do
      attribute?(:name, String, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse(name: nil)
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:name/, error.message)
  end

  def test_optional_non_nullable_with_valid_value
    person = Structure.new do
      attribute?(:name, String, null: false)
    end

    result = person.parse(name: "Alice")

    assert_equal("Alice", result.name)
  end

  def test_non_nullable_with_nil_default_not_stored
    person = Structure.new do
      attribute(:status, String, default: nil, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse({})
    end

    assert_match(/missing keyword/, error.message)
    assert_match(/:status/, error.message)
  end

  def test_non_nullable_with_valid_default
    person = Structure.new do
      attribute(:status, String, default: "active", null: false)
    end

    result = person.parse({})

    assert_equal("active", result.status)
  end

  def test_non_nullable_with_coercion_returning_nil
    person = Structure.new do
      attribute(:age, Integer, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse(age: nil)
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:age/, error.message)
  end

  def test_non_nullable_with_block_returning_nil
    person = Structure.new do
      attribute(:value, null: false) { |_| nil }
    end

    error = assert_raises(ArgumentError) do
      person.parse(value: "anything")
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:value/, error.message)
  end

  def test_non_nullable_with_block_returning_valid_value
    person = Structure.new do
      attribute(:value, null: false, &:upcase)
    end

    result = person.parse(value: "hello")

    assert_equal("HELLO", result.value)
  end

  def test_nullable_by_default_allows_nil
    person = Structure.new do
      attribute(:name, String)
    end

    result = person.parse(name: nil)

    assert_nil(result.name)
  end

  def test_explicit_null_true_allows_nil
    person = Structure.new do
      attribute(:name, String, null: true)
    end

    result = person.parse(name: nil)

    assert_nil(result.name)
  end

  def test_multiple_non_nullable_attributes
    person = Structure.new do
      attribute(:id, String, null: false)
      attribute(:email, String, null: false)
      attribute?(:name, String, null: false)
    end

    result = person.parse(id: "123", email: "test@example.com", name: "Alice")

    assert_equal("123", result.id)
    assert_equal("test@example.com", result.email)
    assert_equal("Alice", result.name)
  end

  def test_mixed_nullable_and_non_nullable
    person = Structure.new do
      attribute(:id, String, null: false)
      attribute(:description, String, null: true)
    end

    result = person.parse(id: "123", description: nil)

    assert_equal("123", result.id)
    assert_nil(result.description)
  end

  def test_nested_structure_non_nullable
    address = Structure.new do
      attribute(:street, String, null: false)
    end

    person = Structure.new do
      attribute(:address, address, null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse(address: nil)
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:address/, error.message)
  end

  def test_array_type_non_nullable
    person = Structure.new do
      attribute(:tags, [String], null: false)
    end

    error = assert_raises(ArgumentError) do
      person.parse(tags: nil)
    end

    assert_match(/cannot be null:/, error.message)
    assert_match(/:tags/, error.message)
  end

  def test_array_type_non_nullable_with_valid_value
    person = Structure.new do
      attribute(:tags, [String], null: false)
    end

    result = person.parse(tags: ["ruby", "rails"])

    assert_equal(["ruby", "rails"], result.tags)
  end
end
