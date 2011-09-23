require 'minitest/autorun'

begin
  require 'pry'
rescue LoadError
end

require 'structure'

class Person < Structure
  key  :name
  key  :location, Location
  one  :partner, Person
  many :friends, Person
end

class Location < Structure
  key :lon, Float
  key :lat, Float
end

class TestWrapper < MiniTest::Unit::TestCase
  def test_lazy_eval
    wrapped = Structure::Wrapper.new(:Foo)
    assert_raises(NameError) { wrapped.unwrap.class }
    ::Kernel.const_set(:Foo, 1)
    assert_kind_of Fixnum, wrapped.unwrap
  end
end

class TestCollection < MiniTest::Unit::TestCase
  def test_push
    ary = Structure::Collection.new(Integer)
    assert_raises(TypeError) { ary.push('1') }
    ary.push(*(1..3).to_a)
    assert_equal 3, ary.count
  end
end

class TestStructure < MiniTest::Unit::TestCase
  def test_enumeration
    assert_respond_to Person.new, :map
  end

  def test_accessors
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  def test_key_errors
    assert_raises(NameError) { Person.key :class }
    assert_raises(TypeError) { Person.key :foo, String, 1 }
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

  def test_typechecking_for_wrapped_classes
    person = Person.new
    person.location = Location.new
    assert_kind_of Location, person.location
  end

  def test_many_relationship
    person = Person.new
    assert_equal [], person.friends

    person.friends << Person.new
    assert_equal 1, person.friends.size
    assert_equal 0, person.friends.first.friends.size

    person.friends.build(:name => 'Joe')
    assert_equal 2, person.friends.count
    assert_equal 'Joe', person.friends.last.name
  end

  def test_one_relationship
    person = Person.new
    assert_equal nil, person.partner

    person.partner = Person.new(:name => 'Jane')
    assert_equal 'Jane', person.partner.name

    person.build_partner(:name => 'Mel')
    assert_equal 'Mel', person.partner.name
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
    require 'structure/ext/active_support'

    assert_equal true,  person.as_json(:only => :name).has_key?(:name)
    assert_equal false, person.as_json(:except => :name).has_key?(:name)
  end
end
