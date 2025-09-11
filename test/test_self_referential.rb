# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestSelfReferential < Minitest::Test
  def test_self_reference_in_attribute
    # Test that we can use :self as a type for self-referential structures
    classification = Structure.new do
      attribute(:display_name, String)
      attribute(:classification_id, String)
      attribute(:parent, :self, default: nil)
    end

    root = classification.parse(
      display_name: "Electronics",
      classification_id: "electronics",
      parent: nil,
    )

    child = classification.parse(
      display_name: "Computers",
      classification_id: "computers",
      parent: {
        display_name: "Electronics",
        classification_id: "electronics",
        parent: nil,
      },
    )

    assert_equal("Electronics", root.display_name)
    assert_nil(root.parent)

    assert_equal("Computers", child.display_name)
    assert_instance_of(classification, child.parent)
    assert_equal("Electronics", child.parent.display_name)
    assert_nil(child.parent.parent)
  end

  def test_tree_node_with_self_children
    tree_node = Structure.new do
      attribute(:value, String)
      attribute(:children, [:self], default: [])
    end

    root = tree_node.parse(
      value: "root",
      children: [
        { value: "child1", children: [] },
        {
          value: "child2",
          children: [
            { value: "grandchild", children: [] },
          ],
        },
      ],
    )

    assert_equal("root", root.value)
    assert_equal(2, root.children.length)
    assert_instance_of(tree_node, root.children[0])
    assert_equal("child1", root.children[0].value)
    assert_equal("child2", root.children[1].value)
    assert_equal(0, root.children[0].children.length)
    assert_equal(1, root.children[1].children.length)
    assert_equal("grandchild", root.children[1].children[0].value)
  end

  def test_linked_list_with_self
    list_node = Structure.new do
      attribute(:data, Integer)
      attribute(:next_node, :self, default: nil)
    end

    head = list_node.parse(
      data: 1,
      next_node: {
        data: 2,
        next_node: {
          data: 3,
          next_node: nil,
        },
      },
    )

    assert_equal(1, head.data)
    assert_instance_of(list_node, head.next_node)
    assert_equal(2, head.next_node.data)
    assert_equal(3, head.next_node.next_node.data)
    assert_nil(head.next_node.next_node.next_node)
  end

  def test_binary_tree_with_self
    binary_tree = Structure.new do
      attribute(:value, Integer)
      attribute(:left, :self, default: nil)
      attribute(:right, :self, default: nil)
    end

    root = binary_tree.parse(
      value: 10,
      left: {
        value: 5,
        left: { value: 3, left: nil, right: nil },
        right: { value: 7, left: nil, right: nil },
      },
      right: {
        value: 15,
        left: { value: 12, left: nil, right: nil },
        right: { value: 20, left: nil, right: nil },
      },
    )

    assert_equal(10, root.value)
    assert_instance_of(binary_tree, root.left)
    assert_instance_of(binary_tree, root.right)
    assert_equal(5, root.left.value)
    assert_equal(3, root.left.left.value)
    assert_equal(7, root.left.right.value)
    assert_equal(15, root.right.value)
    assert_equal(12, root.right.left.value)
    assert_equal(20, root.right.right.value)
  end

  def test_graph_node_with_self_array
    graph_node = Structure.new do
      attribute(:id, String)
      attribute(:connections, [:self], default: [])
    end

    node_a = graph_node.parse(
      id: "A",
      connections: [
        { id: "B", connections: [] },
        {
          id: "C",
          connections: [
            { id: "D", connections: [] },
          ],
        },
      ],
    )

    assert_equal("A", node_a.id)
    assert_equal(2, node_a.connections.length)
    assert_instance_of(graph_node, node_a.connections[0])
    assert_equal("B", node_a.connections[0].id)
    assert_equal("C", node_a.connections[1].id)
    assert_equal("D", node_a.connections[1].connections[0].id)
  end

  def test_deeply_nested_tree_with_self
    tree_node = Structure.new do
      attribute(:level, Integer)
      attribute(:children, [:self], default: [])
    end

    deep_tree = {
      level: 0,
      children: [
        {
          level: 1,
          children: [
            {
              level: 2,
              children: [
                {
                  level: 3,
                  children: [],
                },
              ],
            },
          ],
        },
      ],
    }

    root = tree_node.parse(deep_tree)

    assert_equal(0, root.level)
    assert_equal(1, root.children[0].level)
    assert_equal(2, root.children[0].children[0].level)
    assert_equal(3, root.children[0].children[0].children[0].level)
  end

  def test_nil_handling_with_self
    node = Structure.new do
      attribute(:value, String)
      attribute(:child, :self, default: nil)
    end

    root = node.parse(value: "root", child: nil)

    assert_equal("root", root.value)
    assert_nil(root.child)
  end

  def test_empty_children_array_with_self
    tree_node = Structure.new do
      attribute(:name, String)
      attribute(:children, [:self], default: [])
    end

    leaf = tree_node.parse(name: "leaf", children: [])

    assert_equal("leaf", leaf.name)
    assert_empty(leaf.children)
    assert_empty(leaf.children)
  end

  def test_mixed_types_with_self_reference
    # Test a more complex structure with multiple types including self-reference
    file_system = Structure.new do
      attribute(:name, String)
      attribute(:size, Integer, default: 0)
      attribute(:is_directory, :boolean, default: false)
      attribute(:children, [:self], default: [])
      attribute(:parent, :self, default: nil)
    end

    root = file_system.parse(
      name: "root",
      is_directory: true,
      children: [
        {
          name: "file1.txt",
          size: 1024,
          is_directory: false,
          children: [],
        },
        {
          name: "folder",
          is_directory: true,
          children: [
            {
              name: "file2.txt",
              size: 2048,
              is_directory: false,
            },
          ],
        },
      ],
    )

    assert_equal("root", root.name)
    assert(root.is_directory)
    assert_equal(2, root.children.length)

    file1 = root.children[0]

    assert_equal("file1.txt", file1.name)
    assert_equal(1024, file1.size)
    refute(file1.is_directory)

    folder = root.children[1]

    assert_equal("folder", folder.name)
    assert(folder.is_directory)
    assert_equal(1, folder.children.length)

    file2 = folder.children[0]

    assert_equal("file2.txt", file2.name)
    assert_equal(2048, file2.size)
    refute(file2.is_directory)
  end
end
