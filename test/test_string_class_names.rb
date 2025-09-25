# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestStringClassNames < Minitest::Test
  def setup
    Object.const_set(:Fixtures, Module.new) unless defined?(::Fixtures)
  end

  def teardown
    Object.send(:remove_const, :Fixtures) if defined?(::Fixtures)
  end

  def test_basic_string_class_name
    create_fixture("SimpleClass") do
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
    create_fixture("Item") do
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
    # Create a module for this test's fixtures
    Fixtures.const_set(:Store, Module.new)

    Fixtures::Store.const_set(:Order, Structure.new do
      attribute(:id, String)
      attribute(:items, ["OrderItem"])
      attribute(:customer, "Customer")
    end)

    Fixtures::Store.const_set(:OrderItem, Structure.new do
      attribute(:name, String)
      attribute(:order, "Order")
    end)

    Fixtures::Store.const_set(:Customer, Structure.new do
      attribute(:name, String)
      attribute(:orders, ["Order"])
    end)

    order_data = {
      "id" => "order-123",
      "customer" => { "name" => "John Doe" },
      "items" => [
        { "name" => "Widget" },
        { "name" => "Gadget" },
      ],
    }

    order = Fixtures::Store::Order.parse(order_data)

    assert_instance_of(Fixtures::Store::Customer, order.customer)
    assert_equal(2, order.items.length)
    assert_instance_of(Fixtures::Store::OrderItem, order.items[0])
    assert_instance_of(Fixtures::Store::OrderItem, order.items[1])

    # Test circular reference back
    item_with_order = {
      "name" => "Special Item",
      "order" => {
        "id" => "nested-order",
        "customer" => { "name" => "Jane" },
        "items" => [],
      },
    }
    item = Fixtures::Store::OrderItem.parse(item_with_order)

    assert_instance_of(Fixtures::Store::Order, item.order)
    assert_instance_of(Fixtures::Store::Customer, item.order.customer)
  end

  def test_nested_modules
    Fixtures.const_set(:Blog, Module.new)

    create_fixture("User") do
      attribute(:name, String)
    end

    # Move User into Blog namespace
    Fixtures::Blog.const_set(:User, Fixtures.send(:remove_const, :User))

    Fixtures::Blog.const_set(:Post, Structure.new do
      attribute(:title, String)
      attribute(:author, "User")
    end)

    post_data = {
      "title" => "Hello World",
      "author" => { "name" => "Alice" },
    }

    post = Fixtures::Blog::Post.parse(post_data)

    assert_instance_of(Fixtures::Blog::Post, post)
    assert_instance_of(Fixtures::Blog::User, post.author)
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
    item_class = create_fixture("BackCompat") do
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
    simple_class = create_fixture("MixedRef") do
      attribute(:value, String)
    end

    wrapper = Structure.new do
      attribute(:string_ref, "Fixtures::MixedRef")
      attribute(:direct_ref, simple_class)
      attribute(:string_array, ["Fixtures::MixedRef"])
      attribute(:direct_array, [simple_class])
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

    Fixtures::App::Models.const_set(:InnerClass, Structure.new do
      attribute(:inner_value, String)
    end)

    Fixtures::App::Models.const_set(:MiddleClass, Structure.new do
      attribute(:middle_value, String)
      attribute(:inner, "InnerClass")
    end)

    Fixtures::App::Services.const_set(:OuterClass, Structure.new do
      attribute(:outer_value, String)
      attribute(:middle, "Fixtures::App::Models::MiddleClass")
    end)

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
    create_fixture("CachedClass") do
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
    Fixtures.const_set(:Department, Structure.new do
      attribute(:name, String)
      attribute(:manager, "Employee")
    end)

    Fixtures.const_set(:Employee, Structure.new do
      attribute(:name, String)
      attribute(:department, "Department")
    end)

    dept_data = {
      "name" => "Engineering",
      "manager" => { "name" => "Bob" },
    }

    dept = Fixtures::Department.parse(dept_data)

    assert_instance_of(Fixtures::Department, dept)
    assert_instance_of(Fixtures::Employee, dept.manager)
  end

  private

  def create_fixture(class_name, &block)
    klass = Structure.new(&block)
    Fixtures.const_set(class_name, klass)
    klass
  end
end
