require 'minitest/autorun'
require 'minitest/pride'
require './structure'

Location = Struct.new(:res) do
  include Structure
  [:latitude, :longitude].each { |key| attribute(key) { res.fetch(key) } }
end

class StructureTest < MiniTest::Test
  def setup
    @location = Location.new(latitude: 10, longitude: 20)
  end

  def test_class_returns_attribute_names
    assert_equal [:latitude, :longitude], Location.attribute_names
  end

  def test_casts_itself_to_struct
    struct = Location.to_struct
    assert_equal 'Struct::Location', struct.name
    assert_equal 1, struct.new(latitude: 1).latitude
  end

  def test_cast_to_struct_only_once
    out, err = capture_io do
      2.times { Location.to_struct }
    end
    assert_empty err
  end

  def test_subclassing_does_not_have_side_effects
    subclass = Class.new(Location) do
      attribute(:name) { 'foo' }
    end
    obj = subclass.new(latitude: 10, longitude: 20)
    assert_equal({ latitude: 10, longitude: 20, name: 'foo' }, obj.attributes)
  end

  def test_attributes
    assert_equal 10, @location.latitude
    assert_equal 20, @location.longitude
  end

  def test_returns_attributes
    assert_equal({ latitude: 10, longitude: 20 }, @location.attributes)
    assert_equal @location.to_h, @location.attributes
  end

  def test_compares
    @other = Location.new(longitude: 20, latitude: 10)
    assert @location == @other
    assert @location.eql?(@other)
  end

  def test_pretty_inspects
    assert_equal '#<Location latitude=10, longitude=20>', @location.inspect
    assert_equal @location.to_s, @location.inspect
  end

  def test_truncates_long_arrays_when_pretty_inspecting
    klass = Class.new { include Structure }
    klass.attribute(:ary) { ['a'] }
    assert_includes klass.new.inspect, 'ary=["a"]'
    klass.attribute(:ary) { ('a'..'z').to_a }
    assert_includes klass.new.inspect, 'ary=["a", "b", "c"...]'
  end
end
