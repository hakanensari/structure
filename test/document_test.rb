require File.expand_path('../helper.rb', __FILE__)

class Person < Document
  key  :name
  key  :single, Boolean, :default => true
  one  :location
  many :friends,  :class_name => 'Person'
end

class Location < Document
  key :lon, Float
  key :lat, Float
end

class TestDocument < Test::Unit::TestCase
  def test_enumeration
    assert_respond_to Person.new, :map
  end

  def test_accessors
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  def test_converter
    assert_kind_of Person, Person(Person.new)
    assert_kind_of Person, Person(:name => 'John')
    assert_raise(TypeError) { Person('John') }
  end

  def test_errors
    assert_raise(NameError) { Person.key :class }
    assert_raise(TypeError) { Person.key :foo, Object }
    assert_raise(TypeError) { Person.key :foo, :default => 1 }
  end

  def test_defaults
    assert_equal true, Person.create.single?
  end

  def test_typecheck
    location = Location.new

    location.lon = '100'
    assert_equal 100.0, location.lon

    location.lon = nil
    assert_nil location.lon
  end

  def test_one
    person = Person.new

    person.location = Location.new(:lon => 2.0)
    assert_equal 2.0, person.location.lon

    person.create_location :lon => 1.0
    assert_equal 1.0, person.location.lon
  end

  def test_many
    person = Person.new

    person.friends.create
    person.friends.create :name => 'John'
    assert_equal 2, person.friends.size
    assert_equal 0, person.friends.last.friends.size

    friend = Person.new

    person.friends = [friend]
    assert_equal 1, person.friends.size
    assert_equal 0, friend.friends.size

    person.friends << friend
    assert_equal 2, person.friends.size
    assert_equal 0, friend.friends.size
    assert_equal 0, person.friends.last.friends.size

    person.friends.clear
    assert_equal 0, person.friends.size
    assert       person.friends.empty?
  end

  def test_to_hash
    person = Person.new
    person.friends.create :name => 'John'
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
