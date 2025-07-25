# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestCoreStructure < Minitest::Test
  def test_new_returns_data_class
    klass = Structure.new

    assert_kind_of(Class, klass)
  end

  def test_new_with_attribute_creates_data_class_with_attribute
    person_class = Structure.new do
      attribute(:name)
    end

    assert_equal("John", person_class.new(name: "John").name)
  end

  def test_new_generates_parse_method
    person_class = Structure.new do
      attribute(:name)
    end

    assert_respond_to(person_class, :parse)
  end

  def test_parse_method_accepts_keyword_arguments
    person_class = Structure.new do
      attribute(:name)
    end

    person = person_class.parse(name: "John")

    assert_equal("John", person.name)
  end

  def test_kwargs_override_data
    person_class = Structure.new do
      attribute(:name, String)
    end

    person = person_class.parse({ "name" => "Data Value" }, name: "Kwargs Override")

    assert_equal("Kwargs Override", person.name)
  end

  def test_parse_method_accepts_hash_data
    person_class = Structure.new do
      attribute(:name)
    end

    person = person_class.parse({ "name" => "Jane" })

    assert_equal("Jane", person.name)
  end

  def test_attribute_with_from_parameter_maps_keys
    person_class = Structure.new do
      attribute(:name, from: "Name")
    end

    person = person_class.parse({ "Name" => "Alice" })

    assert_equal("Alice", person.name)
  end

  def test_attribute_with_transformation_block
    order_class = Structure.new do
      attribute(:total) do |data|
        "#{data} USD"
      end
    end

    order = order_class.parse(total: "29.99")

    assert_equal("29.99 USD", order.total)
  end

  def test_attribute_with_both_type_and_block_raises_error
    error = assert_raises(ArgumentError) do
      Structure.new do
        attribute(:value, String, &:to_s)
      end
    end

    assert_match(/Cannot specify both type and block/, error.message)
  end

  def test_attribute_with_default_value
    user_class = Structure.new do
      attribute(:role, String, default: "user")
    end

    user = user_class.parse

    assert_equal("user", user.role)
  end

  def test_attribute_default_value_with_explicit_nil
    config_class = Structure.new do
      attribute(:debug, :boolean, default: false)
    end

    config = config_class.parse(debug: nil)

    assert_nil(config.debug)
  end

  def test_attribute_default_value_overridden_by_data
    product_class = Structure.new do
      attribute(:available, :boolean, default: false)
    end

    product = product_class.parse(available: "true")

    assert(product.available)
  end

  def test_custom_mapping_with_symbol_keys
    person_class = Structure.new do
      attribute(:name, String, from: "full_name")
    end

    # Pass data with symbol keys - this is the edge case
    person = person_class.parse({
      full_name: "Alice", # This should be found (source_key.to_sym)
      name: "Bob", # This should be IGNORED (wrong key)
    })

    # Should get "Alice" not "Bob" - old logic would have incorrectly returned "Bob"
    assert_equal("Alice", person.name)
  end
end
