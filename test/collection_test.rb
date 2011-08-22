require File.expand_path('../helper.rb', __FILE__)

class Foo < Document
  key :bar
end

class TestCollection < Test::Unit::TestCase
  def setup
    Structure::Collection.new(Foo)
  end

  def test_subclassing
    assert       FooCollection < Structure::Collection
    assert_equal Foo, FooCollection.type
  end

  def test_conversion
    item = Foo.new

    assert_equal   item, FooCollection([item]).first
    assert_kind_of FooCollection, FooCollection([item])

    assert_equal   item, FooCollection(item).first
    assert_kind_of FooCollection, FooCollection(item)

    assert_raise(TypeError) { FooCollection('foo') }
  end

  def test_enumeration
    assert_respond_to Foo.new, :map
  end
end
