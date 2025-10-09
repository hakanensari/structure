# frozen_string_literal: true

require "structure"

Category = Structure.new do
  attribute(:name, String)
  attribute(:children, [:self], default: [])
end
