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

  def test_compares
    @other = Location.new(lng: 100, lat: 10)
    assert @location == @other
    assert @location.eql?(@other)
  end

  def test_pretty_inspects
    assert_equal '#<Location latitude=10, longitude=100>', @location.inspect
    assert_equal @location.to_s, @location.inspect
  end

  def test_subclasses
    subclass = Class.new(Location) do
      value(:name) { 'foo' }
    end
    obj = subclass.new(lat: 10, lng: 100)

    assert_equal({ latitude: 10, longitude: 100, name: 'foo' }, obj.values)
  end

  def test_recursively_casts_to_hash
    city_class = Class.new do
      include Structure

      attr :res

      def initialize(res)
        @res = res
      end

      value :name do
        res.fetch(:name)
      end

      value :location do
        Location.new(res.fetch(:loc))
      end
    end

    city = city_class.new(name: 'London', loc: { lat: 51.5, lng: 0.1 })
    assert_equal({ name: 'London', location: { latitude: 51.5, longitude: 0.1 }}, city.to_h)
  end
end
