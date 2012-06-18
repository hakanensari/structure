require_relative 'helper'

class Author < Structure
  key :name
end

class Book < Structure
  many :authors, Author
end

class TestOneToMany < MiniTest::Unit::TestCase
  def setup
    @book = Book.new authors: [{ name: 'Deleuze' }, { name: 'Guattari' }]
  end

  def test_initialize
    assert_equal 'Deleuze', @book.authors.first.name
  end

  def test_write_array
    @book.authors = [{ name: 'Foucault' }]
    assert_equal 'Foucault', @book.authors.first.name
  end

  def test_write_nil
    @book.authors = nil
    assert_equal [], @book.authors
  end

  def test_kind
    assert_kind_of Array, Book.new.authors
  end
end
