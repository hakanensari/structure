# frozen_string_literal: true

require "structure"

Person = Structure.new do
  attribute(:name, String)
  attribute?(:age, Integer)
  attribute(:active, :boolean, default: true)
  attribute(:email, String, from: "email_address")
end
