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
end
