require 'bundler/setup'

require 'test/unit'
require 'active_support/testing/declarative'
require 'active_support/testing/isolation'

begin
  require 'pry'
rescue LoadError
end

require File.expand_path('../../lib/structure', __FILE__)

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
  include ActiveSupport::Testing::Isolation
  class << self; alias should test; end
end

class Person < Structure
  key  :name,     String
  key  :location, Location
  many :friends
end

class Location < Structure
  key :lon, Float
  key :lat, Float
end

class TestStructure < Test::Unit::TestCase
  should "enumerate" do
    assert_respond_to Person.new, :map
  end

  should "define accessors" do
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  should "raise errors" do
    assert_raise(NameError) { Person.key :class }
    assert_raise(TypeError) { Person.key :foo, String, :default => 1 }
  end

  should "store defaults" do
    assert_equal [], Person.new.friends
  end

  should "typecheck" do
    loc = Location.new
    loc.lon = "1"
    assert_kind_of Float, loc.lon

    loc.lon = nil
    assert_nil loc.lon
  end

  should "handle arrays" do
    person = Person.new
    assert_equal [], person.friends

    person.friends << Person.new
    assert_equal 1, person.friends.size
    assert_equal 0, person.friends.first.friends.size
  end

  should "translate to hash" do
    person = Person.new(:name => 'John')
    person.friends << Person.new(:name => 'Jane')
    assert_equal 'John', person.to_hash[:name]
    assert_equal 'Jane', person.to_hash[:friends].first[:name]
  end

  should "translate to JSON" do
    person = Person.new
    person.friends << Person.new
    json = person.to_json
    assert_kind_of Person, JSON.parse(json)
    assert_kind_of Person, JSON.parse(json).friends.first
  end

  should "translate to JSON in a Rails app" do
    person = Person.new
    assert_equal false, person.respond_to?(:as_json)

    require 'active_support/ordered_hash'
    require 'active_support/json'
    require 'structure/rails'
    assert_equal true,  person.as_json(:only => :name).has_key?(:name)
    assert_equal false, person.as_json(:except => :name).has_key?(:name)
  end
end
