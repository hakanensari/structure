# frozen_string_literal: true

require "structure"

# self-referential (parent/children)
Category = Structure.new do
  attribute(:id, Integer)
  attribute(:name, String)
  attribute(:parent, :self)
  attribute(:children, [:self])
end
