# frozen_string_literal: true

require "structure"

User = Structure.new do
  attribute(:id, String, null: false)
  attribute?(:name, String, null: false)
  attribute?(:bio, String)
end
