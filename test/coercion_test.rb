require_relative 'helper'

class Product < Structure
  key :title, lambda(&:capitalize)
  key :cents, Integer
  key :currency, String, default: 'USD'
  key :created_at, default: -> { Time.now }
end

class Perishable < Product
  key :expires_in, Integer, default: 0
end

class CoercionTest < MiniTest::Unit::TestCase
  def setup
    @product = Product.new
  end

  def test_class_coercion
    @product.cents = '100'
    assert_equal 100, @product.cents
  end

  def test_proc_coercion
    @product.title = 'widget'
    assert_equal 'Widget', @product.title
  end

  def test_default
    assert_equal 'USD', @product.currency
    assert_kind_of Time, @product.created_at
  end

  def test_inheritance
    refute Product.blueprint.to_h[:expires_in]
    assert Perishable.blueprint.to_h[:expires_in]
  end
end
