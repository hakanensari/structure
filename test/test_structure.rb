# frozen_string_literal: true

require_relative "helper"
require "structure"

class StructureTest < Minitest::Test
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

  def test_attribute_with_string_type_coerces_to_string
    person_class = Structure.new do
      attribute(:name, String)
    end

    person = person_class.parse(name: 123)

    assert_equal("123", person.name)
  end

  def test_attribute_with_boolean_type_coerces_to_boolean
    person_class = Structure.new do
      attribute(:active, :boolean)
    end

    person = person_class.parse(active: "true")

    assert(person.active)
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

  def test_boolean_attribute_generates_predicate_method
    product_class = Structure.new do
      attribute(:is_available, :boolean)
    end

    product = product_class.new(is_available: true)

    assert_respond_to(product, :is_available?)
    assert_predicate(product, :is_available?)
  end

  def test_boolean_predicate_methods_with_different_names
    user_class = Structure.new do
      attribute(:is_admin, :boolean)
    end

    user = user_class.new(is_admin: true)

    assert_respond_to(user, :is_admin?)
    assert_predicate(user, :is_admin?)
  end

  def test_non_boolean_attributes_do_not_generate_predicate_methods
    user_class = Structure.new do
      attribute(:is_name, String) # String type, not Boolean
    end

    user = user_class.new(is_name: "John")

    refute_respond_to(user, :is_name?)
  end

  def test_transformation_blocks_do_not_generate_predicate_methods
    order_class = Structure.new do
      attribute(:is_valid, from: "Valid") do |data|
        data == "yes"
      end
    end

    order = order_class.new(is_valid: true)

    # Transformation blocks don't automatically generate predicate methods
    refute_respond_to(order, :is_valid?)
  end

  def test_clean_boolean_naming_with_from_parameter
    product_class = Structure.new do
      attribute(:available, :boolean, from: "is_available")
    end

    product = product_class.parse({ "is_available" => "true" })

    assert_respond_to(product, :available?)
    assert_predicate(product, :available?)
  end

  def test_array_type_syntax_coerces_array_elements
    product_class = Structure.new do
      attribute(:tags, [String])
    end

    product = product_class.parse(tags: [123, 456, "hello"])

    assert_equal(["123", "456", "hello"], product.tags)
  end


  def test_array_type_syntax_with_booleans
    settings_class = Structure.new do
      attribute(:flags, [:boolean])
    end

    settings = settings_class.parse(flags: ["true", 0, 1, "false", "yes"])

    assert_equal([true, false, true, false, false], settings.flags)
  end

  def test_array_type_syntax_with_custom_lambda
    data_class = Structure.new do
      attribute(:timestamps, [->(val) { Time.at(val.to_i) }])
    end

    data = data_class.parse(timestamps: [1609459200, "1609545600"])

    assert_equal(2, data.timestamps.length)
    assert_instance_of(Time, data.timestamps.first)
    assert_equal(Time.at(1609459200), data.timestamps.first)
    assert_equal(Time.at(1609545600), data.timestamps.last)
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

  def test_nested_object_parsing
    address_class = Structure.new do
      attribute(:street, String)
    end

    person_class = Structure.new do
      attribute(:address, address_class)
    end

    person = person_class.parse(
      address: { street: "Main St" },
    )

    assert_instance_of(address_class, person.address)
    assert_equal("Main St", person.address.street)
  end

  def test_nested_object_array_parsing
    tag_class = Structure.new do
      attribute(:name, String)
    end

    product_class = Structure.new do
      attribute(:tags, [tag_class])
    end

    product = product_class.parse(
      tags: [{ name: "electronics" }],
    )

    assert_equal(1, product.tags.length)
    assert_instance_of(tag_class, product.tags.first)
    assert_equal("electronics", product.tags.first.name)
  end

  def test_nested_object_with_nil_value
    address_class = Structure.new do
      attribute(:street, String)
    end

    person_class = Structure.new do
      attribute(:address, address_class)
    end

    person = person_class.parse(address: nil)

    assert_nil(person.address)
  end

  def test_nested_array_with_nil_value
    tag_class = Structure.new do
      attribute(:name, String)
    end

    product_class = Structure.new do
      attribute(:tags, [tag_class])
    end

    product = product_class.parse(tags: nil)

    assert_nil(product.tags)
  end
end
