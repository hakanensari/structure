require_relative 'helper'

class BlueprintTest < MiniTest::Unit::TestCase
  def setup
    @blueprint = Structure::Blueprint.new
  end

  def test_proc
    @blueprint.add :foo, -> { 1 + 1 }
    assert_equal [:foo, 2], @blueprint.first
  end

  def test_singleton_class
    @blueprint.add :foo, 1
    assert_equal [:foo, 1], @blueprint.first
  end

  def test_dupable_class
    @blueprint.add :foo, []
    ary = @blueprint.first.last
    ary << 1
    assert_equal [], @blueprint.first.last
  end
end
