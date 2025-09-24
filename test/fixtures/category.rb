# frozen_string_literal: true

require "structure"

# self-referential
Category = Structure.new do
  attribute(:id, Integer)
  attribute(:name, String)
  attribute(:children, [:self], default: [])
end

child1 = Category.parse(id: 2, name: "child1")
child2 = Category.parse(id: 1, name: "child2")
parent = Category.parse(id: 1, name: "parent", children: [child1, child2])

puts "Parent: #{parent.name} (id: #{parent.id})"
parent.children.each do |child|
  puts "  Child: #{child.name} (id: #{child.id})"
end
