# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestAfterParse < Minitest::Test
  def test_after_parse_callback_is_called
    callback_called = false
    person_class = Structure.new do
      attribute(:name)

      after_parse do |_instance|
        callback_called = true
      end
    end

    person_class.parse(name: "John")

    assert(callback_called)
  end

  def test_after_parse_receives_parsed_instance
    received_instance = nil
    person_class = Structure.new do
      attribute(:name, String)

      after_parse do |instance|
        received_instance = instance
      end
    end

    person = person_class.parse(name: "John")

    assert_equal(person, received_instance)
  end

  def test_after_parse_can_raise_errors
    person_class = Structure.new do
      attribute?(:name)

      after_parse do |instance|
        raise "Name is required" if instance.name.nil?
      end
    end

    assert_raises(RuntimeError) { person_class.parse({}) }

    # Should work with valid data
    person = person_class.parse(name: "John")

    assert_equal("John", person.name)
  end
end
