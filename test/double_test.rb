require_relative 'helper'

class Country < Structure
  many :cities, City
end

class City < Structure
  attribute :name, String
end

class DoubleTest < MiniTest::Unit::TestCase
  def test_missing_constant
    country = Country.new cities: [{ name: 'New York' }]
    assert_equal 'New York', country.cities.first.name
  end
end

