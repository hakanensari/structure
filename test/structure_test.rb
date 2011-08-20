require File.expand_path('../helper.rb', __FILE__)

class Person < Structure
  key  :name,     :default => 'John Doe'
  one  :location, Location
  many :friends,  Person
end

class Location < Structure
  key :lon, Float
  key :lat, Float
end

class TestStructure < Test::Unit::TestCase
  def test_enumeration
    assert_respond_to Person.new, :map
  end

  def test_accessors
    person = Person.new
    assert_respond_to person, :name
    assert_respond_to person, :name=
  end

  def test_key_errors
    klass = Class.new(Structure)
    assert_raise(NameError) { klass.key :class }
    assert_raise(TypeError) { klass.key :bar, Object }
    assert_raise(TypeError) { klass.key :bar, :default => 1 }
  end

  def test_defaults
    assert_equal 'John Doe', Person.new.name
    assert_equal nil, Person.new.location
    assert_equal [], Person.new.friends
  end

  def test_typecheck
    loc = Location.new
    loc.lon = '100'
    assert_equal 100.0, loc.lon
    loc.lon = nil
    assert_nil loc.lon
  end

  def test_boolean
    klass = Class.new(Structure)
    klass.key :foo, Boolean, :default => false
    assert_equal false, klass.new.foo
  end

  def test_many_relationship
    person = Person.new
    friend = Person.new
    person.friends = [friend]
    assert_equal 1, person.friends.size
    person.friends << friend
    assert_equal 2, person.friends.size
    person.friends.create
    assert_equal 3, person.friends.size
    assert_equal 0, friend.friends.size
  end

  def test_one_relationship
    person = Person.new
    person.create_location :lon => 1.0
    assert_equal 1.0, person.location.lon
    person.location = Location.new(:lon => 2.0)
    assert_equal 2.0, person.location.lon
  end

  def test_to_hash
    person = Person.new
    person.friends << Person.new(:name => 'John')
    assert_equal 'John', person.to_hash[:friends].first[:name]
  end

  def test_json
    person = Person.new
    json = person.to_json
    assert_equal person, JSON.parse(json)
  end

  def test_json_with_nested_structures
    person = Person.new
    person.friends << Person.new
    person.location = Location.new
    json = person.to_json
    assert JSON.parse(json).friends.first.is_a? Person
    assert JSON.parse(json).location.is_a? Location
  end

  def test_json_with_active_support
    require 'active_support/ordered_hash'
    require 'active_support/json'
    person = Person.new
    assert person.as_json(:only => :name).has_key?(:name)
    assert !person.as_json(:except => :name).has_key?(:name)
  end
end
