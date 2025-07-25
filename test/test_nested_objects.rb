# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestNestedObjects < Minitest::Test
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
