require 'minitest/autorun'

begin
  require 'pry'
rescue LoadError
end

require 'structure'
require 'structure/json'

class Person < Structure
  key :name
  key :friends, Array, []
  key :city, City
end

class City < Structure
  key :name
end

class TestStructure < MiniTest::Unit::TestCase
  def test_lazy_evaluation
    wrapper = Structure::Wrapper.new(:Foo)
    assert_raises(NameError) { wrapper.bar }
    assert_raises(NameError) { wrapper.unwrap.bar }

    klass = Class.new { def self.bar; end }
    ::Kernel.const_set(:Foo, klass)
    assert_respond_to wrapper, :bar
    assert_equal Foo, wrapper.unwrap
  end

  def test_enumeration
    assert_respond_to Person.new, :map
  end

  def test_accessors
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  def test_key_errors
    assert_raises(NameError) { Person.key :class }
    assert_raises(TypeError) { Person.key :foo, Hash, 1 }
  end

  def test_key_defaults
    assert_equal [], Person.new.friends
  end

  def test_typecasting
    person = Person.new
    person.name = 123
    assert_kind_of String, person.name

    person.name = nil
    assert_nil person.name
  end

  def test_many_relationship
    person = Person.new
    assert_equal [], person.friends

    person.friends << Person.new
    assert_equal 1, person.friends.size
    assert_equal 0, person.friends.first.friends.size
  end

  def test_new
    person = Person.new(:name => 'John')
    assert_equal 'John', person.name

    other = Person.new(:name => 'Jane', :friends => [person])
    assert_equal 'John', other.friends.first.name
  end

  def test_to_hash
    person = Person.new(:name => 'John')
    person.friends << Person.new(:name => 'Jane')
    hash = person.to_hash

    assert_equal 'John', hash[:name]
    assert_equal 'Jane', hash[:friends].first[:name]
  end

  def test_json
    Person.send :include, Structure::JSON

    person = Person.new(:name => 'John')
    person.friends << Person.new(:name => 'Jane')
    json = person.to_json
    assert_kind_of Person, JSON.parse(json)
    assert_kind_of Person, JSON.parse(json).friends.first
    assert_equal false, person.respond_to?(:as_json)

    require 'active_support/ordered_hash'
    require 'active_support/json'
    load 'structure/json.rb'
    assert_equal true,  person.as_json(:only => :name).has_key?(:name)
    assert_equal false, person.as_json(:except => :name).has_key?(:name)
  end
end
