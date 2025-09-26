# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestThreadSafety < Minitest::Test
  TestItem = Structure.new do
    attribute(:name, String)
    attribute(:value, Integer)
  end

  TestParent = Structure.new do
    attribute(:name, String)
    attribute(:children, ["TestThreadSafety::TestChild"])
  end

  TestChild = Structure.new do
    attribute(:name, String)
    attribute(:parent, "TestThreadSafety::TestParent")
  end

  def test_concurrent_string_class_resolution
    container = Structure.new do
      attribute(:id, String)
      attribute(:item, "TestThreadSafety::TestItem")
    end

    test_data = { "id" => "test", "item" => { "name" => "concurrent", "value" => 42 } }
    results = []
    errors = []
    threads = []

    10.times do |_i|
      threads << Thread.new do
        5.times do
          result = container.parse(test_data.dup)
          results << result
        end
      rescue => e
        errors << e
      end
    end

    threads.each(&:join)

    assert_empty(errors, "Concurrent access should not cause errors: #{errors.map(&:message)}")
    assert_equal(50, results.length, "Should have 50 results (10 threads × 5 iterations)")

    results.each do |result|
      assert_equal("test", result.id)
      assert_instance_of(TestItem, result.item)
      assert_equal("concurrent", result.item.name)
      assert_equal(42, result.item.value)
    end
  end

  def test_concurrent_circular_dependency_resolution
    test_data = {
      "name" => "parent",
      "children" => [
        {
          "name" => "child1",
          "parent" => { "name" => "nested_parent", "children" => [] },
        },
      ],
    }

    results = []
    errors = []
    threads = []

    5.times do
      threads << Thread.new do
        3.times do
          result = TestParent.parse(test_data.dup)
          results << result
        end
      rescue => e
        errors << e
      end
    end

    threads.each(&:join)

    assert_empty(errors, "Circular dependency resolution should be thread-safe")
    assert_equal(15, results.length)

    results.each do |result|
      assert_equal("parent", result.name)
      assert_equal(1, result.children.length)
      assert_instance_of(TestChild, result.children.first)
      assert_equal("child1", result.children.first.name)
      assert_instance_of(TestParent, result.children.first.parent)
    end
  end
end
