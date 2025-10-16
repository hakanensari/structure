# frozen_string_literal: true

require "helper"
require "structure"
require "structure/rbs"
require "tmpdir"
require_relative "fixtures/category"
require_relative "fixtures/person"
require_relative "fixtures/measure"
require_relative "fixtures/product"
require_relative "fixtures/tag_collection"
require_relative "fixtures/tree_node"
require_relative "fixtures/user"

class TestRBS < Minitest::Test
  def setup
    @created_classes = []
  end

  def teardown
    @created_classes.each do |class_name|
      self.class.send(:remove_const, class_name) if self.class.const_defined?(class_name)
    end
  end

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

  def test_emit_rbs_custom_methods
    expected = File.read("test/fixtures/product.rbs")
    actual = Structure::RBS.emit(Product)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_with_array_types
    expected = File.read("test/fixtures/tag_collection.rbs")
    actual = Structure::RBS.emit(TagCollection)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_mixed_array_and_self_referential
    expected = File.read("test/fixtures/tree_node.rbs")
    actual = Structure::RBS.emit(TreeNode)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbs_non_nullable
    expected = File.read("test/fixtures/user.rbs")
    actual = Structure::RBS.emit(User)

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

  def test_write_rbs_returns_nil
    Dir.mktmpdir do |dir|
      result = Structure::RBS.write(String, dir: dir)

      assert_nil(result)

      assert(Dir.empty?(dir))
    end
  end

  def test_emit_rbs_to_h_signature_no_bare_array_type
    klass = create_test_class(:TestBareArrayType) do
      attribute(:unknown_array, Array)
    end

    rbs = Structure::RBS.emit(klass)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    refute_match(/Array\?\s*[,}]/, to_h_line, "to_h should not contain bare Array? type")
  end

  def test_emit_rbs_to_h_signature_no_bare_hash_type
    klass = create_test_class(:TestBareHashType) do
      attribute(:unknown_hash, Hash)
    end

    rbs = Structure::RBS.emit(klass)
    to_h_line = rbs.lines.find { |line| line.include?("def to_h:") }

    refute_match(/Hash\?\s*[,}]/, to_h_line, "to_h should not contain bare Hash? type")
  end

  private

  def create_test_class(class_name, &block)
    klass = Structure.new(&block)
    self.class.const_set(class_name, klass)
    @created_classes << class_name.to_sym
    klass
  end
end
