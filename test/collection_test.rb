require File.expand_path('../helper.rb', __FILE__)

class Foo < Structure
  key :bar
end

class TestCollection < Test::Unit::TestCase
  def test_new
    assert Structure::Collection.new(Foo) < Array
    assert_equal 'FooCollection', Structure::Collection.new(Foo).to_s
    assert_raise(TypeError) { Structure::Collection.new(Module.new) }
  end

  def test_typecheck
    collection = Structure::Collection.new(Foo).new
    collection << { :bar => 'baz' }
    assert_equal 'baz', collection.first.bar
    assert_raise(TypeError) { collection << 'foo' }
  end

  def test_collection_idioms
    collection = Structure::Collection.new(Foo).new
    collection << Foo.new
    assert_equal 1, collection.size
    collection.create(:bar => 'baz')
    assert_equal 2, collection.size
    assert_equal 'baz', collection.last.bar
    collection.clear
    assert_equal 0, collection.size
    assert collection.empty?
  end
end
