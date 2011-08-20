require File.expand_path('../helper.rb', __FILE__)

class City < Structure
  include Static

  key  :name
  many :neighborhoods, Neighborhood
end

class Neighborhood < Structure
  key :name
end

class Dummy < Structure
  include Static

  key :name
end

class TestStatic < Test::Unit::TestCase
  def fixture(klass, path)
    klass.instance_variable_set(:@records, nil)
    klass.instance_variable_set(:@increment_id, nil)
    fixture = File.expand_path("../fixtures/#{path}.yml", __FILE__)
    klass.set_data_path(fixture)
  end

  def test_class_enumeration
    assert_respond_to City, :map
  end

  def test_all
    fixture City, 'cities'
    cities = City.all
    assert_kind_of City, cities.first
    assert_equal 2, cities.size
  end

  def test_find
    fixture City, 'cities'
    assert 'New York', City.find(1).name
    assert_nil City.find(4)
  end

  def test_data_without_ids
    fixture City, 'cities_without_ids'
    assert_equal 'New York', City.find(1).name
    assert_equal 'Paris', City.find(3).name
  end

  def test_auto_increment
    fixture City, 'cities_without_ids'
    fixture Dummy, 'cities_without_ids'
    assert_equal 'New York', City.find(1).name
    assert_equal 'New York', Dummy.find(1).name
  end

  def test_nesting
    fixture City, 'cities_with_neighborhoods'
    assert_kind_of Neighborhood, City.first.neighborhoods.first
  end
end
