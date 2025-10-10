# frozen_string_literal: true

require_relative "person"
require_relative "category"
require_relative "product"
require_relative "tag_collection"
require_relative "tree_node"

# Test that application code using Structure classes type-checks correctly. These should all pass Steep with no
# warnings.

person = Person.parse(name: "Alice", age: 30, email_address: "alice@example.com")
person.name
person.age
person.active
person.active?
person.email

category = Category.parse(name: "Electronics", children: [
  { name: "Computers" },
  { name: "Phones" },
])
category.name
category.children
category.children&.first&.name

product = Product.parse(name: "Laptop", price: 999.99)
product.name
product.price
product.discounted_price
product.discounted_price(0.2)

built_product = Product.build("Widget")
built_product.name
built_product.price

tag_collection = TagCollection.parse(tags: ["ruby", "gem"], numbers: [1, 2, 3], flags: [true, false])
tag_collection.tags
tag_collection.numbers
tag_collection.flags

tree_node = TreeNode.parse(name: "Root", tags: ["important"], children: [
  { name: "Child 1", tags: ["leaf"], children: [] },
  { name: "Child 2", tags: ["branch"], children: [] },
])
tree_node.name
tree_node.tags
tree_node.children
tree_node.children&.first&.name
tree_node.children&.first&.tags
