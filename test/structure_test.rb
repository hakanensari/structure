require 'minitest/autorun'
require 'structure'

class StructureTest < MiniTest::Test
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

  def setup
    @location = Location.new(lat: 10, lng: 100)
  end

  def test_has_value
    assert_equal 10, @location.latitude
    assert_equal 100, @location.longitude
  end
end
