# frozen_string_literal: true

require "helper"
require "structure"
require "tapioca"
require "tapioca/dsl"
require "tapioca/dsl/compilers/structure"

require_relative "fixtures/category"
require_relative "fixtures/person"
require_relative "fixtures/product"
require_relative "fixtures/tag_collection"
require_relative "fixtures/tree_node"
require_relative "fixtures/user"

class TestTapioca < Minitest::Test
  def test_gather_constants
    constants = Tapioca::Dsl::Compilers::Structure.gather_constants

    assert_includes(constants, Person)
    assert_includes(constants, Category)
    refute_includes(constants, String)
  end

  def test_emit_rbi
    expected = File.read("test/fixtures/person.rbi")
    actual = emit_rbi(Person)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbi_self_referential
    expected = File.read("test/fixtures/category.rbi")
    actual = emit_rbi(Category)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbi_custom_methods
    expected = File.read("test/fixtures/product.rbi")
    actual = emit_rbi(Product)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbi_with_array_types
    expected = File.read("test/fixtures/tag_collection.rbi")
    actual = emit_rbi(TagCollection)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbi_mixed_array_and_self_referential
    expected = File.read("test/fixtures/tree_node.rbi")
    actual = emit_rbi(TreeNode)

    assert_equal(expected.strip, actual.strip)
  end

  def test_emit_rbi_non_nullable
    expected = File.read("test/fixtures/user.rbi")
    actual = emit_rbi(User)

    assert_equal(expected.strip, actual.strip)
  end

  private

  def emit_rbi(klass)
    pipeline = Tapioca::Dsl::Pipeline.new(
      requested_constants: [klass],
      requested_compilers: [Tapioca::Dsl::Compilers::Structure],
    )
    compiler = Tapioca::Dsl::Compilers::Structure.new(pipeline, RBI::Tree.new, klass)
    tree = RBI::Tree.new
    compiler.instance_variable_set(:@root, tree)
    compiler.decorate
    tree.string
  end
end
