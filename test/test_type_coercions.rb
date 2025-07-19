# frozen_string_literal: true

require_relative "helper"
require "structure"

class TypeCoercionsTest < Minitest::Test
  def test_string_coercion
    person_class = Structure.new do
      attribute(:name, String)
    end

    person = person_class.parse(name: 123)

    assert_equal("123", person.name)
  end

  def test_boolean_coercion
    person_class = Structure.new do
      attribute(:active, :boolean)
    end

    person = person_class.parse(active: "true")

    assert(person.active)
  end

  def test_string_arrays
    product_class = Structure.new do
      attribute(:tags, [String])
    end

    product = product_class.parse(tags: [123, 456, "hello"])

    assert_equal(["123", "456", "hello"], product.tags)
  end

  def test_boolean_arrays
    settings_class = Structure.new do
      attribute(:flags, [:boolean])
    end

    settings = settings_class.parse(flags: ["true", 0, 1, "false", "yes"])

    assert_equal([true, false, true, false, false], settings.flags)
  end

  def test_custom_lambda_arrays
    data_class = Structure.new do
      attribute(:timestamps, [->(val) { Time.at(val.to_i) }])
    end

    data = data_class.parse(timestamps: [1609459200, "1609545600"])

    assert_equal(2, data.timestamps.length)
    assert_instance_of(Time, data.timestamps.first)
    assert_equal(Time.at(1609459200), data.timestamps.first)
    assert_equal(Time.at(1609545600), data.timestamps.last)
  end

  def test_integer_arrays
    data_class = Structure.new do
      attribute(:numbers, [Integer])
    end

    data = data_class.parse(numbers: ["1", "2", 3.5, "4"])

    assert_equal([1, 2, 3, 4], data.numbers)
  end

  def test_float_arrays
    data_class = Structure.new do
      attribute(:prices, [Float])
    end

    data = data_class.parse(prices: ["19.99", 25, "30.50"])

    assert_equal([19.99, 25.0, 30.5], data.prices)
  end

  def test_nil_arrays
    data_class = Structure.new do
      attribute(:tags, [String])
    end

    data = data_class.parse(tags: nil)

    assert_nil(data.tags)
  end

  def test_empty_arrays
    data_class = Structure.new do
      attribute(:tags, [String])
    end

    data = data_class.parse(tags: [])

    assert_empty(data.tags)
  end
end
