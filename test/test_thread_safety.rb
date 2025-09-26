# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestThreadSafety < Minitest::Test
  def setup
    Object.const_set(:ThreadTest, Module.new) unless defined?(::ThreadTest)
  end

  def teardown
    Object.send(:remove_const, :ThreadTest) if defined?(::ThreadTest)
  end

  def test_concurrent_string_class_resolution
    # Define a Structure class that uses string class names
    ThreadTest.const_set(:Item, Structure.new do
      attribute(:name, String)
      attribute(:value, Integer)
    end)

    container = Structure.new do
      attribute(:id, String)
      attribute(:item, "ThreadTest::Item")
    end

    # Test data
    test_data = { "id" => "test", "item" => { "name" => "concurrent", "value" => 42 } }

    # Track results from all threads
    results = []
    errors = []
    threads = []

    # Create multiple threads that simultaneously parse using string class resolution
    10.times do |_i|
      threads << Thread.new do
        # Each thread parses the same data structure multiple times
        5.times do
          result = container.parse(test_data.dup)
          results << result
        end
      rescue => e
        errors << e
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify no errors occurred
    assert_empty(errors, "Concurrent access should not cause errors: #{errors.map(&:message)}")

    # Verify all results are correct
    assert_equal(50, results.length, "Should have 50 results (10 threads × 5 iterations)")

    results.each do |result|
      assert_equal("test", result.id)
      assert_instance_of(ThreadTest::Item, result.item)
      assert_equal("concurrent", result.item.name)
      assert_equal(42, result.item.value)
    end
  end

  def test_concurrent_circular_dependency_resolution
    # Create circular dependencies to stress test the resolution
    ThreadTest.const_set(:Parent, Structure.new do
      attribute(:name, String)
      attribute(:children, ["ThreadTest::Child"])
    end)

    ThreadTest.const_set(:Child, Structure.new do
      attribute(:name, String)
      attribute(:parent, "ThreadTest::Parent")
    end)

    # Test data with circular references
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

    # Multiple threads parsing circular dependencies
    5.times do
      threads << Thread.new do
        3.times do
          result = ThreadTest::Parent.parse(test_data.dup)
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
      assert_instance_of(ThreadTest::Child, result.children.first)
      assert_equal("child1", result.children.first.name)
      assert_instance_of(ThreadTest::Parent, result.children.first.parent)
    end
  end
end
