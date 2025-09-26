# frozen_string_literal: true

require "helper"
require "structure"
require "structure/rbs"
require "tmpdir"
require_relative "fixtures/category"
require_relative "fixtures/person"
require_relative "fixtures/measure"

class TestRBS < Minitest::Test
  def test_emit_rbs
    expected = File.read("test/fixtures/person.rbs")
    actual = Structure::RBS.emit(Person)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_self_referential
    expected = File.read("test/fixtures/category.rbs")
    actual = Structure::RBS.emit(Category)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_plain_data
    expected = File.read("test/fixtures/measure.rbs")
    actual = Structure::RBS.emit(Measure)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_non_data_class
    result = Structure::RBS.emit(String)

    assert_nil(result)

    result = Structure::RBS.emit(Array)

    assert_nil(result)
  end

  def test_emit_rbs_anonymous_class
    anon_structure = Structure.new do
      attribute(:name, String)
    end
    result = Structure::RBS.emit(anon_structure)

    assert_nil(result)
  end

  def test_write_rbs
    Dir.mktmpdir do |dir|
      path = Structure::RBS.write(Person, dir: dir)

      assert_equal(File.join(dir, "person.rbs"), path)
      assert_path_exists(path)

      content = File.read(path)
      expected = File.read("test/fixtures/person.rbs")

      assert_equal(expected.strip, content.strip)
    end
  end

  def test_write_rbs_returns_nil_for_non_data_class
    Dir.mktmpdir do |dir|
      # Should return nil for non-Data classes
      result = Structure::RBS.write(String, dir: dir)

      assert_nil(result)

      # Should not create any files
      assert(Dir.empty?(dir))
    end
  end

  def test_write_rbs_returns_nil_for_anonymous_class
    Dir.mktmpdir do |dir|
      # Should return nil for anonymous classes
      anon_data = Data.define(:x, :y)
      result = Structure::RBS.write(anon_data, dir: dir)

      assert_nil(result)

      # Should not create any files
      assert(Dir.empty?(dir))
    end
  end

  def test_emit_rbs_with_array_types
    # Create a named class constant
    self.class.const_set(:TestArrayClass, Structure.new do
      attribute(:tags, [String])
      attribute(:numbers, [Integer])
      attribute(:flags, [:boolean])
    end)

    rbs = Structure::RBS.emit(self.class::TestArrayClass)

    assert_match(/attr_reader tags: Array\[String\]\?/, rbs)
    assert_match(/attr_reader numbers: Array\[Integer\]\?/, rbs)
    assert_match(/attr_reader flags: Array\[bool\]\?/, rbs)

    # Arrays without self-referential types don't generate parse_data
    # They use the basic parse signature with Hash[String | Symbol, untyped]
    assert_match(/def self\.parse: \(\?\(Hash\[String \| Symbol, untyped\]\), \*\*untyped\) -> TestRBS::TestArrayClass/, rbs)
    refute_match(/type parse_data/, rbs)
  ensure
    self.class.send(:remove_const, :TestArrayClass) if self.class.const_defined?(:TestArrayClass)
  end

  def test_emit_rbs_mixed_array_and_self_referential
    # Create a named class constant
    self.class.const_set(:TestMixedClass, Structure.new do
      attribute(:name, String)
      attribute(:tags, [String])
      attribute(:children, [:self])
    end)

    rbs = Structure::RBS.emit(self.class::TestMixedClass)

    # Check attribute readers
    assert_match(/attr_reader name: String\?/, rbs)
    assert_match(/attr_reader tags: Array\[String\]\?/, rbs)
    assert_match(/attr_reader children: Array\[TestRBS::TestMixedClass\]\?/, rbs)

    # Check parse_data
    assert_match(/\?name: untyped/, rbs)
    assert_match(/\?tags: Array\[untyped\]/, rbs)
    assert_match(/\?children: Array\[TestRBS::TestMixedClass \| parse_data\]/, rbs)
  ensure
    self.class.send(:remove_const, :TestMixedClass) if self.class.const_defined?(:TestMixedClass)
  end

  def test_rbs_should_use_class_name_not_instance_keyword
    # This test demonstrates the RBS generation issue where 'instance'
    # should be replaced with the actual class name for Steep compatibility
    self.class.const_set(:TestArrayList, Structure.new do
      attribute(:items, [:array, String])
    end)

    rbs = Structure::RBS.emit(self.class::TestArrayList)

    # The issue: these should return the class name, not 'instance'
    # Current (broken): -> instance
    # Expected (fixed): -> TestRBS::TestArrayList
    refute_match(/-> instance/, rbs)
    assert_match(/-> TestRBS::TestArrayList/, rbs)
  ensure
    self.class.send(:remove_const, :TestArrayList) if self.class.const_defined?(:TestArrayList)
  end
end
