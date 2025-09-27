# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestStringClassNames < Minitest::Test
  def setup
    Object.const_set(:Fixtures, Module.new)
  end

  def teardown
    Object.send(:remove_const, :Fixtures)
  end

  def test_basic_string_class_name
    create_test_class("SimpleClass") do
      attribute(:name, String)
    end

    wrapper = Structure.new do
      attribute(:id, String)
      attribute(:item, "Fixtures::SimpleClass")
    end

    data = { "id" => "123", "item" => { "name" => "Test" } }
    result = wrapper.parse(data)

    assert_instance_of(Fixtures::SimpleClass, result.item)
    assert_equal("Test", result.item.name)
  end

  def test_array_of_string_class
    create_test_class("Item") do
      attribute(:name, String)
      attribute(:price, Integer)
    end

    wrapper = Structure.new do
      attribute(:items, ["Fixtures::Item"])
    end

    data = {
      "items" => [
        { "name" => "Item1", "price" => "100" },
        { "name" => "Item2", "price" => "200" },
      ],
    }
    result = wrapper.parse(data)

    assert_equal(2, result.items.length)
    assert_instance_of(Fixtures::Item, result.items[0])
    assert_instance_of(Fixtures::Item, result.items[1])
  end

  def test_circular_dependencies
    create_test_class("Order") do
      attribute(:id, String)
      attribute(:items, ["Fixtures::OrderItem"])
      attribute(:customer, "Fixtures::Customer")
    end

    create_test_class("OrderItem") do
      attribute(:name, String)
      attribute(:order, "Fixtures::Order")
    end

    create_test_class("Customer") do
      attribute(:name, String)
      attribute(:orders, ["Fixtures::Order"])
    end

    order_data = {
      "id" => "order-123",
      "customer" => { "name" => "John Doe" },
      "items" => [
        { "name" => "Widget" },
        { "name" => "Gadget" },
      ],
    }

    order = Fixtures::Order.parse(order_data)

    assert_instance_of(Fixtures::Customer, order.customer)
    assert_equal(2, order.items.length)
    assert_instance_of(Fixtures::OrderItem, order.items[0])
    assert_instance_of(Fixtures::OrderItem, order.items[1])

    # Test circular reference back
    item_with_order = {
      "name" => "Special Item",
      "order" => {
        "id" => "nested-order",
        "customer" => { "name" => "Jane" },
        "items" => [],
      },
    }
    item = Fixtures::OrderItem.parse(item_with_order)

    assert_instance_of(Fixtures::Order, item.order)
    assert_instance_of(Fixtures::Customer, item.order.customer)
  end

  def test_non_existent_class_raises_error
    wrapper = Structure.new do
      attribute(:item, "NonExistentClass")
    end

    error = assert_raises(NameError) do
      wrapper.parse({ "item" => { "foo" => "bar" } })
    end

    assert_match(/Unable to resolve class 'NonExistentClass'/, error.message)
  end

  def test_backwards_compatibility_with_class_constants
    item_class = create_test_class("BackCompat") do
      attribute(:name, String)
    end

    wrapper = Structure.new do
      attribute(:direct_class, item_class)
      attribute(:array_class, [item_class])
    end

    data = {
      "direct_class" => { "name" => "Direct" },
      "array_class" => [{ "name" => "Array1" }, { "name" => "Array2" }],
    }

    result = wrapper.parse(data)

    assert_instance_of(Fixtures::BackCompat, result.direct_class)
    assert_equal(2, result.array_class.length)
    result.array_class.each { |item| assert_instance_of(Fixtures::BackCompat, item) }
  end

  def test_mixed_string_and_direct_references
    klass = create_test_class("MixedRef") do
      attribute(:value, String)
    end

    wrapper = Structure.new do
      attribute(:string_ref, "Fixtures::MixedRef")
      attribute(:direct_ref, klass)
      attribute(:string_array, ["Fixtures::MixedRef"])
      attribute(:direct_array, [klass])
    end

    data = {
      "string_ref" => { "value" => "A" },
      "direct_ref" => { "value" => "B" },
      "string_array" => [{ "value" => "C" }],
      "direct_array" => [{ "value" => "D" }],
    }

    result = wrapper.parse(data)

    assert_instance_of(Fixtures::MixedRef, result.string_ref)
    assert_instance_of(Fixtures::MixedRef, result.direct_ref)
    assert_instance_of(Fixtures::MixedRef, result.string_array[0])
    assert_instance_of(Fixtures::MixedRef, result.direct_array[0])
  end

  def test_deeply_nested_string_references
    Fixtures.const_set(:App, Module.new)
    Fixtures::App.const_set(:Models, Module.new)
    Fixtures::App.const_set(:Services, Module.new)

    create_test_class("InnerClass", namespace: Fixtures::App::Models) do
      attribute(:inner_value, String)
    end

    create_test_class("MiddleClass", namespace: Fixtures::App::Models) do
      attribute(:middle_value, String)
      attribute(:inner, "InnerClass")
    end

    create_test_class("OuterClass", namespace: Fixtures::App::Services) do
      attribute(:outer_value, String)
      attribute(:middle, "Fixtures::App::Models::MiddleClass")
    end

    data = {
      "outer_value" => "outer",
      "middle" => {
        "middle_value" => "middle",
        "inner" => {
          "inner_value" => "inner",
        },
      },
    }

    result = Fixtures::App::Services::OuterClass.parse(data)

    assert_instance_of(Fixtures::App::Services::OuterClass, result)
    assert_instance_of(Fixtures::App::Models::MiddleClass, result.middle)
    assert_instance_of(Fixtures::App::Models::InnerClass, result.middle.inner)
  end

  def test_string_class_resolution_caching
    create_test_class("CachedClass") do
      attribute(:value, String)
    end

    wrapper = Structure.new do
      attribute(:items, ["Fixtures::CachedClass"])
    end

    # Parse multiple items - coercion should be cached internally
    data = {
      "items" => [
        { "value" => "1" },
        { "value" => "2" },
        { "value" => "3" },
      ],
    }

    result1 = wrapper.parse(data)

    assert_equal(3, result1.items.length)
    result1.items.each { |item| assert_instance_of(Fixtures::CachedClass, item) }

    # Multiple parses should reuse the same cached coercion
    result2 = wrapper.parse(data)

    assert_equal(3, result2.items.length)
    result2.items.each { |item| assert_instance_of(Fixtures::CachedClass, item) }
  end

  def test_string_references_within_fixtures_namespace
    # Test that classes within the Fixtures namespace can reference each other
    # using just the class name (without the Fixtures:: prefix)
    create_test_class("Department") do
      attribute(:name, String)
      attribute(:manager, "Employee")
    end

    create_test_class("Employee") do
      attribute(:name, String)
      attribute(:department, "Department")
    end

    dept_data = {
      "name" => "Engineering",
      "manager" => { "name" => "Bob" },
    }

    dept = Fixtures::Department.parse(dept_data)

    assert_instance_of(Fixtures::Department, dept)
    assert_instance_of(Fixtures::Employee, dept.manager)
  end

  private

  def create_test_class(class_name, namespace: Fixtures, &block)
    klass = Structure.new(&block)
    namespace.const_set(class_name, klass)

    klass
  end
end
