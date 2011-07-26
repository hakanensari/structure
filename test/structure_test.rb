require 'rubygems'
require 'bundler/setup'
require 'test/unit'

require File.expand_path("../../lib/structure", __FILE__)

class Person
  include Structure

  attribute   :name
  attribute   :age, Integer
  attribute   :married, Boolean, :default => false
  embeds_one  :spouse 
  embeds_many :children
end

class TestStructure < Test::Unit::TestCase
  def test_enumeration
    person = Person.new
    assert_respond_to(person, :map)
  end

  def test_method_generation
    person = Person.new
    assert_respond_to(person, :name)
    assert_respond_to(person, :name=)
    assert_respond_to(person, :name?)
  end

  def test_attribute_errors
    assert_raise(NameError) { Person.attribute :class }
    assert_raise(TypeError) { Person.attribute :foo, Object }
    assert_raise(TypeError) { Person.attribute :foo, :default => 1 }
  end

  def test_default_attributes
    assert_equal({ :name => nil, :age => nil, :married => false, :spouse => nil, :children => [] }, Person.default_attributes)
  end

  def test_initialization
    person = Person.new(:name => 'John', :age => 28)
    assert_equal('John', person.name)
    assert_equal(28, person.age)
  end

  def test_typecasting
    person = Person.new

    person.age = "28"
    assert_equal(28, person.age)

    person.age = nil
    assert_nil(person.age)
  end

  def test_presence
    person = Person.new

    person.married = nil
    assert(!person.married?)

    person.married = false
    assert(!person.married?)

    person.married = true
    assert(person.married?)
  end

  def test_default_type
    person = Person.new
    person.name = 1
    assert(person.name.is_a? String)
  end

  def test_boolean_typecasting
    person = Person.new

    person.married = 'false'
    assert(person.married == false)

    person.married = 'FALSE'
    assert(person.married == false)

    person.married = '0'
    assert(person.married == false)

    person.married = 'foo'
    assert(person.married == true)

    person.married = 0
    assert(person.married == false)

    person.married = 10
    assert(person.married == true)
  end

  def test_defaults
    person = Person.new
    assert_equal(false, person.married)
    assert_equal(nil, person.name)
    assert_equal(nil, person.spouse)
    assert_equal([], person.children)
  end

  def test_array
    person = Person.new
    child = Person.new
    person.children << child
    assert_equal(1, person.children.count)
    assert_equal(0, child.children.count)
  end

  def test_json
    person = Person.new(:name => 'Joe')
    json = person.to_json
    assert_equal(person, JSON.parse(json))
  end

  def test_json_with_nested_structures
    person = Person.new
    person.children << Person.new
    json = person.to_json
    assert(JSON.parse(json).children.first.is_a? Person)
  end

  def test_json_with_active_support
    require 'active_support/ordered_hash'
    require 'active_support/json'

    person = Person.new
    assert(person.as_json(:only => :name).has_key?(:name))
    assert(!person.as_json(:except => :name).has_key?(:name))
  end
end
