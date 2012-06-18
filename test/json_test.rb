require_relative 'helper'

class JSONTest < MiniTest::Unit::TestCase
  def json
    '{"json_class":"Structure",
      "name":"John",
      "friend":{"name":"Jane"},
      "cities":["Zurich"]}'.gsub(/\s+/, '')
  end

  def setup
    @person = Structure.new name: 'John',
                            friend: { name: 'Jane' },
                            cities: ['Zurich']
  end

  def test_to_json
    assert_equal json, @person.to_json
  end

  def test_parse_json
    assert_equal @person, JSON.parse(json)
  end

  def test_active_support
    refute_respond_to @person, :as_json
    require 'active_support/ordered_hash'
    require 'active_support/json'
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    load 'structure.rb'
    $VERBOSE = original_verbosity
    assert @person.as_json(only: :name).has_key?(:name)
    refute @person.as_json(except: :name).has_key?(:name)
  end
end
