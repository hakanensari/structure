# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestRecursiveToH < Minitest::Test
  def test_nested_structure_to_h
    inner = Structure.new { attribute(:x) }
    outer = Structure.new { attribute(:inner, inner) }

    result = outer.parse(inner: { x: 1 }).to_h

    assert_kind_of(Hash, result[:inner])
    assert_equal(1, result[:inner][:x])
  end

  def test_array_of_structures_to_h
    item = Structure.new { attribute(:x) }
    list = Structure.new { attribute(:items, [item]) }

    result = list.parse(items: [{ x: 1 }, { x: 2 }]).to_h

    assert_kind_of(Array, result[:items])
    assert_kind_of(Hash, result[:items][0])
    assert_kind_of(Hash, result[:items][1])
  end

  def test_deeply_nested_structures_to_h
    a = Structure.new { attribute(:val) }
    b = Structure.new { attribute(:a, a) }
    c = Structure.new { attribute(:b, b) }

    result = c.parse(b: { a: { val: 1 } }).to_h

    assert_kind_of(Hash, result[:b])
    assert_kind_of(Hash, result[:b][:a])
    assert_equal(1, result[:b][:a][:val])
  end

  def test_preserves_non_structure_values
    mixed = Structure.new do
      attribute(:name, String)
      attribute(:created_at, Date)
      attribute(:metadata, Hash)
      attribute(:tags, Array)
    end

    mixed_data = {
      name: "Test",
      created_at: "2024-01-15",
      metadata: { key: "value" },
      tags: ["ruby", "gem"],
    }

    parsed = mixed.parse(mixed_data)
    result = parsed.to_h

    assert_equal("Test", result[:name])
    assert_equal(Date.new(2024, 1, 15), result[:created_at])
    assert_equal({ key: "value" }, result[:metadata])
    assert_equal(["ruby", "gem"], result[:tags])
  end

  def test_handles_nil_values
    person = Structure.new do
      attribute(:name, String)
      attribute(:email, String)
    end

    parsed = person.parse({ name: "Alice", email: nil })
    result = parsed.to_h

    assert_equal("Alice", result[:name])
    assert_nil(result[:email])
  end

  def test_handles_false_values
    settings = Structure.new do
      attribute(:enabled, :boolean)
      attribute(:name, String)
    end

    parsed = settings.parse({ enabled: false, name: "Test" })
    result = parsed.to_h

    refute(result[:enabled])
    assert_equal("Test", result[:name])
  end

  def test_handles_nil_in_arrays
    collection = Structure.new do
      attribute(:raw_values, Array)
      attribute(:mixed_values) do |data|
        data # Pass through as-is
      end
    end

    data = {
      raw_values: [1, nil, "test", false],
      mixed_values: [1, nil, { key: "value" }, false],
    }

    parsed = collection.parse(data)
    result = parsed.to_h

    assert_equal([1, nil, "test", false], result[:raw_values])
    assert_equal([1, nil, { key: "value" }, false], result[:mixed_values])
  end

  def test_custom_objects_with_to_h
    custom_class = Class.new do
      def to_h
        { custom: true }
      end
    end

    struct = Structure.new do
      attribute(:obj) { |_| custom_class.new }
    end

    result = struct.parse({ obj: "anything" }).to_h

    assert_equal({ custom: true }, result[:obj])
  end

  def test_nested_custom_objects_in_arrays
    money = Class.new do
      def initialize(val)
        @val = val
      end

      def to_h
        { amount: @val }
      end
    end

    struct = Structure.new do
      attribute(:prices) { |data| data.map { |v| money.new(v) } }
    end

    result = struct.parse({ prices: [10, 20] }).to_h

    assert_equal([{ amount: 10 }, { amount: 20 }], result[:prices])
  end
end
