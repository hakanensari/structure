# frozen_string_literal: true

require "structure"

Category = Structure.new do
  attribute(:name, String)
  attribute(:children, [:self], default: [])
end

cat = Category.parse(children: [Category.new(name: "root", children: [])])
cat.to_h
