# frozen_string_literal: true

require "structure"

TreeNode = Structure.new do
  attribute(:name, String)
  attribute(:tags, [String])
  attribute(:children, [:self])
end
