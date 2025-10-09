# frozen_string_literal: true

require_relative "helper"
require "structure"

# rubocop:disable Lint/NestedMethodDefinition, Style/ClassMethodsDefinitions
class TestCustomMethods < Minitest::Test
  def test_instance_method_with_attribute_access
    user_class = Structure.new do
      attribute(:age, Integer)

      def adult?
        age >= 18
      end
    end

    assert_predicate(user_class.parse(age: 25), :adult?)
    refute_predicate(user_class.parse(age: 10), :adult?)
  end

  def test_class_method
    user_class = Structure.new do
      attribute(:role, String)

      def self.create_admin
        parse(role: "admin")
      end
    end

    assert_equal("admin", user_class.create_admin.role)
  end

  def test_multiple_instance_methods
    person_class = Structure.new do
      attribute(:first_name, String)
      attribute(:last_name, String)

      def full_name
        "#{first_name} #{last_name}"
      end

      def initials
        "#{first_name[0]}#{last_name[0]}"
      end
    end

    p = person_class.parse(first_name: "John", last_name: "Doe")

    assert_equal("John Doe", p.full_name)
    assert_equal("JD", p.initials)
  end

  def test_custom_methods_with_type_coercion
    product_class = Structure.new do
      attribute(:price, Float)
      attribute(:quantity, Integer)

      def total
        price * quantity
      end
    end

    p = product_class.parse(price: "19.99", quantity: "3")

    assert_in_delta(59.97, p.total)
  end

  def test_custom_methods_with_key_mapping
    user_class = Structure.new do
      attribute(:active, :boolean, from: "IsActive")

      def status
        active ? "online" : "offline"
      end
    end

    assert_equal("online", user_class.parse("IsActive" => "true").status)
    assert_equal("offline", user_class.parse("IsActive" => "false").status)
  end

  def test_custom_methods_with_defaults
    config_class = Structure.new do
      attribute(:timeout, Integer, default: 30)

      def timeout_ms
        timeout * 1000
      end
    end

    assert_equal(30_000, config_class.parse({}).timeout_ms)
  end

  def test_custom_methods_with_optional_attributes
    user_class = Structure.new do
      attribute(:name, String)
      attribute?(:nickname, String)

      def display_name
        nickname || name
      end
    end

    assert_equal("Bob", user_class.parse(name: "Robert", nickname: "Bob").display_name)
    assert_equal("Robert", user_class.parse(name: "Robert").display_name)
  end

  def test_custom_methods_with_transformation_blocks
    order_class = Structure.new do
      attribute(:total) do |val|
        val.to_f.round(2)
      end

      def formatted_total
        "$#{total}"
      end
    end

    assert_equal("$19.99", order_class.parse(total: "19.989").formatted_total)
  end

  def test_custom_methods_with_after_parse
    calls = []

    user_class = Structure.new do
      attribute(:age, Integer)

      def valid?
        age > 0
      end

      after_parse do |user|
        calls << user.valid?
      end
    end

    user_class.parse(age: 25)

    assert_equal([true], calls)
  end

  def test_overriding_data_methods
    person_class = Structure.new do
      attribute(:name, String)

      def to_s
        "Person: #{name}"
      end
    end

    assert_equal("Person: Alice", person_class.parse(name: "Alice").to_s)
  end

  def test_custom_methods_with_nested_structures
    address_class = Structure.new do
      attribute(:city, String)
      attribute(:country, String)
    end

    user_class = Structure.new do
      attribute(:name, String)
      attribute(:address, address_class)

      def location
        "#{address.city}, #{address.country}"
      end
    end

    u = user_class.parse(name: "Alice", address: { city: "Boston", country: "USA" })

    assert_equal("Boston, USA", u.location)
  end

  def test_custom_methods_with_array_types
    project_class = Structure.new do
      attribute(:tags, [String])

      def tag_count
        tags.length
      end

      def has_tag?(tag)
        tags.include?(tag)
      end
    end

    p = project_class.parse(tags: ["ruby", "gem", "testing"])

    assert_equal(3, p.tag_count)
    assert(p.has_tag?("ruby"))
    refute(p.has_tag?("python"))
  end

  def test_class_and_instance_methods_together
    user_class = Structure.new do
      attribute(:name, String)
      attribute(:age, Integer)

      def adult?
        age >= 18
      end

      def self.legal_age
        18
      end
    end

    assert_equal(18, user_class.legal_age)
    assert_predicate(user_class.parse(name: "Bob", age: 25), :adult?)
  end

  def test_methods_preserve_data_functionality
    person_class = Structure.new do
      attribute(:name, String)
      attribute(:age, Integer)

      def greeting
        "Hi!"
      end
    end

    p = person_class.parse(name: "Alice", age: 30)

    assert_equal([:name, :age], p.class.members)
    assert_equal({ name: "Alice", age: 30 }, p.to_h)
    assert_equal("Alice", p.name)
    assert_equal(30, p.age)

    assert_equal("Hi!", p.greeting)
  end

  def test_custom_methods_with_self_referential_types
    tree_class = Structure.new do
      attribute(:value, String)
      attribute(:children, [:self], default: [])

      def leaf?
        children.empty?
      end

      def depth
        return 1 if leaf?

        1 + children.map(&:depth).max
      end
    end

    tree = tree_class.parse(
      value: "root",
      children: [
        { value: "child1", children: [{ value: "grandchild" }] },
        { value: "child2" },
      ],
    )

    refute_predicate(tree, :leaf?)
    assert_predicate(tree.children[1], :leaf?)
    assert_equal(3, tree.depth)
  end
end
# rubocop:enable Lint/NestedMethodDefinition, Style/ClassMethodsDefinitions
