# frozen_string_literal: true

require "structure"

TagCollection = Structure.new do
  attribute(:tags, [String])
  attribute(:numbers, [Integer])
  attribute(:flags, [:boolean])
end
