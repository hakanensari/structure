require 'minitest/autorun'
require 'structure'

class Location
  include Structure

  attr :res

  def initialize(res)
    @res = res
  end

  value :latitude do
    res.fetch(:lat)
  end

  value :longitude do
    res.fetch(:lng)
  end
end

class StructureTest < MiniTest::Test
  def setup
    @location = Location.new(lat: 10, lng: 100)
  end

  def test_has_value
    assert_equal 10, @location.latitude
    assert_equal 100, @location.longitude
  end

  def test_class_returns_value_names
    assert_equal [:latitude, :longitude], Location.value_names
  end

  def test_returns_values
    assert_equal({ latitude: 10, longitude: 100 }, @location.values)
    assert_equal @location.to_h, @location.values
  end
end
