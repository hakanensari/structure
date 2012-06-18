require_relative 'helper'

class InitializeTest < MiniTest::Unit::TestCase
  def test_name_clash
    assert_raises ArgumentError do
      Structure.new class: 'foo'
    end
  end
end
