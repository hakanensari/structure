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
      result = Structure::RBS.write(String, dir: dir)

      assert_nil(result)

      assert(Dir.empty?(dir))
    end
  end

  def test_write_rbs_returns_nil_for_anonymous_class
    Dir.mktmpdir do |dir|
      anon_data = Data.define(:x, :y)
      result = Structure::RBS.write(anon_data, dir: dir)

      assert_nil(result)

      assert(Dir.empty?(dir))
    end
  end

  def test_emit_rbs_with_array_types
    self.class.const_set(:TestArrayClass, Structure.new do
      attribute(:tags, [String])
      attribute(:numbers, [Integer])
      attribute(:flags, [:boolean])
    end)

    rbs = Structure::RBS.emit(self.class::TestArrayClass)

    assert_match(/attr_reader tags: Array\[String\]\?/, rbs)
    assert_match(/attr_reader numbers: Array\[Integer\]\?/, rbs)
    assert_match(/attr_reader flags: Array\[bool\]\?/, rbs)

    assert_match(/def self\.parse: \(\?\(Hash\[String \| Symbol, untyped\]\), \*\*untyped\) -> TestRBS::TestArrayClass/, rbs)
    refute_match(/type parse_data/, rbs)
  ensure
    self.class.send(:remove_const, :TestArrayClass) if self.class.const_defined?(:TestArrayClass)
  end

  def test_emit_rbs_mixed_array_and_self_referential
    self.class.const_set(:TestMixedClass, Structure.new do
      attribute(:name, String)
      attribute(:tags, [String])
      attribute(:children, [:self])
    end)

    rbs = Structure::RBS.emit(self.class::TestMixedClass)

    assert_match(/attr_reader name: String\?/, rbs)
    assert_match(/attr_reader tags: Array\[String\]\?/, rbs)
    assert_match(/attr_reader children: Array\[TestRBS::TestMixedClass\]\?/, rbs)

    assert_match(/\?name: untyped/, rbs)
    assert_match(/\?tags: Array\[untyped\]/, rbs)
    assert_match(/\?children: Array\[TestRBS::TestMixedClass \| parse_data\]/, rbs)
  ensure
    self.class.send(:remove_const, :TestMixedClass) if self.class.const_defined?(:TestMixedClass)
  end

  def test_emit_rbs_to_h_signature_present
    self.class.const_set(:TestBareTypes, Structure.new do
      attribute(:tags, [String])
    end)

    rbs = Structure::RBS.emit(self.class::TestBareTypes)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    refute_nil(to_h_line, "to_h method signature should be present")
  ensure
    self.class.send(:remove_const, :TestBareTypes) if self.class.const_defined?(:TestBareTypes)
  end

  def test_emit_rbs_to_h_signature_no_bare_array_type
    self.class.const_set(:TestBareArrayType, Structure.new do
      attribute(:unknown_array, Array)
    end)

    rbs = Structure::RBS.emit(self.class::TestBareArrayType)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    refute_match(/Array\?\s*[,}]/, to_h_line, "to_h should not contain bare Array? type")
  ensure
    self.class.send(:remove_const, :TestBareArrayType) if self.class.const_defined?(:TestBareArrayType)
  end

  def test_emit_rbs_to_h_signature_no_bare_hash_type
    self.class.const_set(:TestBareHashType, Structure.new do
      attribute(:unknown_hash, Hash)
    end)

    rbs = Structure::RBS.emit(self.class::TestBareHashType)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    refute_match(/Hash\?\s*[,}]/, to_h_line, "to_h should not contain bare Hash? type")
  ensure
    self.class.send(:remove_const, :TestBareHashType) if self.class.const_defined?(:TestBareHashType)
  end

  def test_emit_rbs_to_h_signature_typed_array
    self.class.const_set(:TestTypedArray, Structure.new do
      attribute(:tags, [String])
    end)

    rbs = Structure::RBS.emit(self.class::TestTypedArray)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    assert_match(/Array\[String\]\?/, to_h_line, "to_h should contain Array[String]? for typed arrays")
  ensure
    self.class.send(:remove_const, :TestTypedArray) if self.class.const_defined?(:TestTypedArray)
  end

  def test_emit_rbs_to_h_signature_unknown_array_as_untyped
    self.class.const_set(:TestUnknownArray, Structure.new do
      attribute(:unknown_array, Array)
    end)

    rbs = Structure::RBS.emit(self.class::TestUnknownArray)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    assert_match(/Array\[untyped\]\?/, to_h_line, "to_h should contain Array[untyped]? for unknown arrays")
  ensure
    self.class.send(:remove_const, :TestUnknownArray) if self.class.const_defined?(:TestUnknownArray)
  end

  def test_emit_rbs_to_h_signature_unknown_hash_as_untyped
    self.class.const_set(:TestUnknownHash, Structure.new do
      attribute(:unknown_hash, Hash)
    end)

    rbs = Structure::RBS.emit(self.class::TestUnknownHash)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    assert_match(/Hash\[untyped, untyped\]\?/, to_h_line, "to_h should contain Hash[untyped, untyped]? for unknown hashes")
  ensure
    self.class.send(:remove_const, :TestUnknownHash) if self.class.const_defined?(:TestUnknownHash)
  end
end
