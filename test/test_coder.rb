# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestCoder < Minitest::Test
  def setup
    @settings_class = Structure.new do
      attribute(:theme, String, default: "light")
      attribute(:count, Integer)
    end
  end

  def test_dump_nil_returns_nil
    assert_nil(@settings_class.dump(nil))
  end

  def test_dump_instance_returns_hash
    instance = @settings_class.parse(theme: "dark", count: "42")

    result = @settings_class.dump(instance)

    assert_equal({ theme: "dark", count: 42 }, result)
  end

  def test_dump_invalid_raises_error
    assert_raises(NoMethodError) do
      @settings_class.dump(false)
    end
  end

  def test_load_nil_returns_nil
    assert_nil(@settings_class.load(nil))
  end

  def test_load_hash_returns_instance
    hash = { theme: "dark", count: 42 }

    result = @settings_class.load(hash)

    assert_instance_of(@settings_class, result)
    assert_equal("dark", result.theme)
    assert_equal(42, result.count)
  end

  def test_roundtrip
    original = @settings_class.parse(theme: "dark", count: "42")

    dumped = @settings_class.dump(original)
    loaded = @settings_class.load(dumped)

    assert_equal(original, loaded)
  end

  def test_roundtrip_with_nested_structures
    address_class = Structure.new do
      attribute(:city, String)
      attribute(:zip, String)
    end

    person_class = Structure.new do
      attribute(:name, String)
      attribute(:address, address_class)
    end

    original = person_class.parse(
      name: "Alice",
      address: { city: "NYC", zip: "10001" },
    )

    dumped = person_class.dump(original)
    loaded = person_class.load(dumped)

    assert_equal(original, loaded)
    assert_equal("NYC", loaded.address.city)
  end
end
