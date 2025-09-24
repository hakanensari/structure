# frozen_string_literal: true

require "structure"

# float, array
Product = Structure.new do
  attribute(:name, String)
  attribute(:price, Float)
  attribute(:tags, [:array, String])
end
