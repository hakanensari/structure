require_relative "helper"
require_relative "../lib/structure/double"

class Person
  include Structure

  def initialize(data)
    @data = data
  end

  attribute(:name) do
    @data.fetch(:name)
  end
end unless defined?(Person)

class DoubleTest < Minitest::Test
  def test_predicate_methods
    klass = build_anonymous_class do
      attribute(:foo?) { false }
    end
    mock = klass.double.new(foo: true)
    assert mock.foo?
    assert_equal mock.foo, mock.foo?
  end

  def test_casts_to_double
    person = Person.double.new("name" => "Jane")
    assert_equal "Jane", person.name
  end

  def test_defines_custom_methods
    double = build_anonymous_class.double do
      def foo
      end
    end

    assert_respond_to double.new, :foo
  end

  def test_inherits_public_methods
    mod = Module.new do
      def foo
      end
    end

    klass = build_anonymous_class do
      include mod

      def bar
      end
    end

    assert_respond_to klass.double.new, :foo
    assert_respond_to klass.double.new, :bar
  end

  def test_does_not_inherit_nonpublic_methods
    klass = build_anonymous_class do
      protected

      def foo
      end

      private

      def bar
      end
    end

    double = klass.double
    assert_raises(NoMethodError) { double.new.send(:foo) }
    assert_raises(NoMethodError) { double.new.send(:bar) }
  end

  def test_undefines_builder_method
    klass = build_anonymous_class
    assert_raises(NoMethodError) { klass.double.send(:double) }
  end
end
