$:.push File.expand_path('../../lib', __FILE__)

require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'

class Test::Unit::TestCase
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    if method_defined? test_name
      raise "#{test_name} is already defined in #{self}"
    end
    define_method test_name, &block
  end
end

class Person < Structure
  key  :name
  key  :age, Integer
  many :friends
end

class TestStructure < Test::Unit::TestCase
  test "should enumerate" do
    assert_respond_to Person.new, :map
  end

  test "should define accessors" do
    assert_respond_to Person.new, :name
    assert_respond_to Person.new, :name=
  end

  test "should raise errors" do
    assert_raise(NameError) { Person.key :class }
    assert_raise(TypeError) { Person.key :foo, String, :default => 1 }
  end

  test "should store defaults" do
    assert_equal [], Person.new.friends
  end

  test "should typecheck" do
    person = Person.new
    person.age = '18'
    assert_equal 18, person.age

    person.age = nil
    assert_nil person.age
  end

  test "should handle arrays" do
    person = Person.new
    assert_equal [], person.friends

    person.friends << Person.new
    assert_equal 1, person.friends.size
    assert_equal 0, person.friends.first.friends.size
  end

  test "should translate to hash" do
    person = Person.new(:name => 'John')
    person.friends << Person.new(:name => 'Jane')
    assert_equal 'John', person.to_hash[:name]
    assert_equal 'Jane', person.to_hash[:friends].first[:name]
  end

  test "should translate to JSON" do
    person = Person.new
    person.friends << Person.new
    json = person.to_json
    assert_kind_of Person, JSON.parse(json)
    assert_kind_of Person, JSON.parse(json).friends.first
  end

  test "should translate to JSON in a Rails app" do
    person = Person.new
    assert_equal false, person.respond_to?(:as_json)

    require 'active_support/ordered_hash'
    require 'active_support/json'
    require 'structure/rails'
    assert_equal true,  person.as_json(:only => :name).has_key?(:name)
    assert_equal false, person.as_json(:except => :name).has_key?(:name)
  end
end

class City < Structure
  key :name
end

class Stadt < Structure
  key :name
end

class TestStatic < Test::Unit::TestCase
  def fix(klass, path)
    klass.instance_variable_set(:@all, nil)
    klass.instance_variable_set(:@id_cnt, nil)
    fixture = File.expand_path("../fixtures/#{path}.yml", __FILE__)
    klass.set_data_file(fixture)
  end

  test "should enumerate at the class level" do
    fix City, 'cities'
    assert_respond_to City, :map
  end

  test "should return all records" do
    fix City, 'cities'
    cities = City.all
    assert_kind_of City, cities.first
    assert_equal 2, cities.size
  end

  test "should find a record" do
    fix City, 'cities'
    assert 'New York', City.find(1).name
    assert_nil City.find(4)
  end

  test "should work if records contain no id field" do
    fix City, 'cities_without_ids'
    assert_equal 'New York', City.find(1).name
    assert_equal 'Paris', City.find(3).name
  end

  test "should auto increment independently in each structure" do
    fix City, 'cities_without_ids'
    fix Stadt, 'cities_without_ids'
    assert_equal 'New York', City.find(1).name
    assert_equal 'New York', Stadt.find(1).name
  end
end
