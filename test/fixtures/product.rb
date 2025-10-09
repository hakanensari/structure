# frozen_string_literal: true

require "structure"

Product = Structure.new do
  attribute(:name, String)
  attribute(:price, Float)

  # steep:ignore:start
  class << self
    def build(name)
      new(name: name, price: 0.0)
    end
  end

  def discounted_price(rate = 0.1)
    (price || 0.0) * (1 - rate)
  end
  # steep:ignore:end
end
