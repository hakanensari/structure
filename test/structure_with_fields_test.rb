require File.expand_path('../helper.rb', __FILE__)

class Product < Structure
  field :title
  field :sku, lambda(&:upcase)
  field :cents, Integer
  field :currency, String, :default => 'USD'
  key :in_stock, :default => true
  field :created_on, :default => lambda { Date.today }
  many :related
end

class Foo < Structure
  field :bar, Hash
end

class TestStructureWithFields < MiniTest::Unit::TestCase
  def setup
    @product = Product.new(:title => 'Widget')
  end

  def test_inheritance
    assert_equal 'USD', Class.new(Product).new.currency
  end

  def test_equal_value
    assert @product == Class.new(Product).new(:title => 'Widget')
    refute @product == Product.new(:title => 'Widget', :sku => '123')
  end

  def test_casting
    @product.title = 1
    assert_kind_of Integer, @product.title

    @product.sku = 'sku-123'
    assert_equal 'SKU-123', @product.sku

    @product.cents = '1'
    assert_kind_of Integer, @product.cents

    @product.related = '1'
    assert_kind_of Array, @product.related
  end

  def test_default_values
    assert_equal nil, @product.cents
    assert_equal 'USD', @product.currency
    assert_equal true, @product.in_stock
    assert_equal [], @product.related
    assert_kind_of Date, @product.created_on
  end

  def test_recursive_hashes
    foo = Foo.new('bar' => { 'baz' => 1 })
    hsh = foo.marshal_dump
    foo.marshal_load(hsh)
    assert_equal({ 'baz' => 1 }, foo.bar)

    json = foo.to_json
    assert foo, JSON.parse(json)
  end

  def test_recursive_array_handling
    related = Product.new
    @product.related << related
    assert_equal [related], @product.related
    assert_equal [], @product.related.first.related
  end
end
