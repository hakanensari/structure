require 'bundler/setup'
require 'test/unit'
begin
  require 'pry'
rescue LoadError
end
require File.expand_path('../../lib/structure', __FILE__)

class Person < Structure
  key  :name
  key  :location, Location
  many :friends
end

class Location < Structure
  key :lon, Float
  key :lat, Float
end

class TestStructure < Test::Unit::TestCase
  def test_wrapper
    wrapper = Structure::Wrapper.new(:Foo)
    assert_raise(NameError) { wrapper.class }
    ::Kernel.const_set(:Foo, 1)
    assert_kind_of Fixnum, wrapper
  end

  def test_enumeration
    assert_respond_to Person.new, :map
  end

  def test_accessors
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  def test_key_errors
    assert_raise(NameError) { Person.key :class }
  end

  def test_key_defaults
    assert_equal [], Person.new.friends
  end

  def test_typechecking
    loc = Location.new
    loc.lon = "1"
    assert_kind_of Float, loc.lon

    loc.lon = nil
    assert_nil loc.lon
  end

  def test_array_type
    person = Person.new
    assert_equal [], person.friends

    person.friends << Person.new
    assert_equal 1, person.friends.size
    assert_equal 0, person.friends.first.friends.size
  end

  def test_to_hash
    person = Person.new(:name => 'John')
    person.friends << Person.new(:name => 'Jane')
    assert_equal 'John', person.to_hash[:name]
    assert_equal 'Jane', person.to_hash[:friends].first[:name]
  end

  def test_json
    person = Person.new
    person.friends << Person.new
    json = person.to_json
    assert_kind_of Person, JSON.parse(json)
    assert_kind_of Person, JSON.parse(json).friends.first

    assert_equal false, person.respond_to?(:as_json)

    require 'active_support/ordered_hash'
    require 'active_support/json'
    require 'structure/active_support'

    assert_equal true,  person.as_json(:only => :name).has_key?(:name)
    assert_equal false, person.as_json(:except => :name).has_key?(:name)
  end
end
