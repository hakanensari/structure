require File.expand_path('../helper.rb', __FILE__)

class Product < Structure
  field :title
  field :sku, lambda { |val| val.to_s.upcase }
  field :cents, Integer
  field :currency, String, :default => 'USD'
  field :in_stock, :default => true
  many :related
end

class Foo < Structure
  field :bar, Hash
end

class TestDefinedStructure < MiniTest::Unit::TestCase
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
  end

  def test_hashes_with_recursion
    foo = Foo.new('bar' => { 'baz' => 1 })
    hsh = foo.marshal_dump
    foo.marshal_load(hsh)
    assert_equal({ 'baz' => 1 }, foo.bar)

    json = foo.to_json
    assert foo, JSON.parse(json)
  end
end
