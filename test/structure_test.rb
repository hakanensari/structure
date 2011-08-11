$:.push File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'

class Book < Structure
  key  :title
  key  :published, Boolean, :default => true
  key  :pages,     Integer
end

class Person < Structure
  key  :name
  one  :partner
  many :friends
  many :parents, :default => 2.times.map { Person.new }
end

class TestStructure < Test::Unit::TestCase
  def test_enumeration
    assert_respond_to Book.new, :map
  end

  def test_accessors
    book = Book.new
    assert_respond_to book, :title
    assert_respond_to book, :title=
  end

  def test_key_errors
    assert_raise(NameError) { Book.key :class }
    assert_raise(TypeError) { Book.key :foo, Object }
    assert_raise(TypeError) { Book.key :foo, :default => 1 }
  end

  def test_default_attributes
    exp = { :title     => nil,
            :published => true,
            :pages => nil }
    assert_equal exp, Book.default_attributes
  end

  def test_initialization
    book = Book.new(:title => 'Foo', :pages => 100)
    assert_equal 'Foo', book.title
    assert_equal 100, book.pages
  end

  def test_typecasting
    book = Book.new

    book.pages = "100"
    assert_equal 100, book.pages

    book.pages = nil
    assert_nil book.pages

    book.title = 1
    book.title = '1'
  end

  def test_boolean_typecasting
    book = Book.new

    book.published = 'false'
    assert book.published == false

    book.published = 'FALSE'
    assert book.published == false

    book.published = '0'
    assert book.published == false

    book.published = 'foo'
    assert book.published == true

    book.published = 0
    assert book.published == false

    book.published = 10
    assert book.published == true
  end

  def test_defaults
    assert_equal nil, Book.new.title
    assert_equal true, Book.new.published
    assert_equal nil, Person.new.partner
    assert_equal [], Person.new.friends
  end

  def test_array
    person = Person.new
    friend = Person.new
    person.friends << person
    assert_equal 1, person.friends.count
    assert_equal 0, friend.friends.count
  end

  def test_many
    person = Person.new
    assert_equal 2, person.parents.size
  end

  def test_json
    book = Book.new(:title => 'Foo')
    json = book.to_json
    assert_equal book, JSON.parse(json)
  end

  def test_json_with_nested_structures
    person = Person.new
    person.friends << Person.new
    person.partner = Person.new
    json = person.to_json
    assert JSON.parse(json).friends.first.is_a? Person
    assert JSON.parse(json).partner.is_a? Person
  end

  def test_json_with_active_support
    require 'active_support/ordered_hash'
    require 'active_support/json'

    book = Book.new
    assert book.as_json(:only => :title).has_key?(:title)
    assert !book.as_json(:except => :title).has_key?(:title)
  end
end
