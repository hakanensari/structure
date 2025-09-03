# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestBooleanPredicates < Minitest::Test
  def test_generates_predicate_methods
    product_class = Structure.new do
      attribute(:is_available, :boolean)
    end

    product = product_class.new(is_available: true)

    assert_respond_to(product, :is_available?)
  end

  def test_predicate_methods_with_different_names
    user_class = Structure.new do
      attribute(:is_admin, :boolean)
    end

    user = user_class.new(is_admin: true)

    assert_respond_to(user, :is_admin?)
  end

  def test_non_boolean_attributes_skip_predicates
    user_class = Structure.new do
      attribute(:is_name, String) # String type, not Boolean
    end

    user = user_class.new(is_name: "John")

    refute_respond_to(user, :is_name?)
  end

  def test_transformation_blocks_skip_predicates
    order_class = Structure.new do
      attribute(:is_valid, from: "Valid") do |data|
        data == "yes"
      end
    end

    order = order_class.new(is_valid: true)

    # Transformation blocks don't automatically generate predicate methods
    refute_respond_to(order, :is_valid?)
  end

  def test_clean_naming_with_from_parameter
    product_class = Structure.new do
      attribute(:available, :boolean, from: "is_available")
    end

    product = product_class.parse({ "is_available" => "true" })

    assert_respond_to(product, :available?)
  end

  def test_attribute_ending_with_question_mark_skips_predicate
    status_class = Structure.new do
      attribute(:active?, :boolean)
    end

    status = status_class.new("active?" => true)

    assert_respond_to(status, :active?)
    refute_respond_to(status, "active??")
  end
end
