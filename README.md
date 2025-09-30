# Structure

[![CI/CD Pipeline](https://github.com/hakanensari/structure/actions/workflows/ci.yml/badge.svg)](https://github.com/hakanensari/structure/actions/workflows/ci.yml)

![Ruby](https://raw.githubusercontent.com/hakanensari/structure/refs/heads/main/images/ruby.png)

**Structure your data**

Turn unruly hashes into clean [Ruby Data](https://docs.ruby-lang.org/en/3.4/Data.html) objects with type coercion.

```ruby
# Before: Hash drilling
user_name = response["user"]["name"]
user_age = response["user"]["age"].to_i
user_active = response["user"]["is_active"] == "true"

# After: Clean, typed objects
user.name     # => "Alice" (String)
user.age      # => 25 (Integer)
user.active?  # => true
```

Built on [Ruby Data](https://docs.ruby-lang.org/en/3.4/Data.html) for immutability, pattern matching, and all the other good stuff. Zero dependencies.

## Installation

Add to your Gemfile:

```ruby
gem "structure"
```

## Usage

### The Basics

```ruby
User = Structure.new do
  attribute(:name, String)
  attribute(:age, Integer)
  attribute(:active, :boolean)
end

user = User.parse({
  "name" => "Alice",
  "age" => "25",
  "active" => "true"
})

user.name     # => "Alice" (String)
user.age      # => 25 (Integer)
user.active   # => true (TrueClass)
user.active?  # => true (predicate method)
```

### Type Coercion

Uses Ruby's built-in coercion methods to convert data:

```ruby
Product = Structure.new do
  attribute(:title, String)      # Uses String(val)
  attribute(:price, Float)       # Uses Float(val)
  attribute(:quantity, Integer)  # Uses Integer(val)
  attribute(:available, :boolean) # Custom boolean logic
end

product = Product.parse({
  "title" => 123,
  "price" => "19.99",
  "quantity" => "5",
  "available" => "1"
})

product.title     # => "123"
product.price     # => 19.99
product.quantity  # => 5
product.available # => true
```

### Key Mapping

Clean up gnarly keys:

```ruby
Person = Structure.new do
  attribute(:name, String, from: "full_name")
  attribute(:active, :boolean, from: "is_active")
end

person = Person.parse({
  "full_name" => "Bob Smith",
  "is_active" => "true"
})

person.name    # => "Bob Smith"
person.active? # => true
```

### Optional Attributes

Structure wraps Data classes. All attributes are required when creating instances, even if their value is `nil`.

```ruby
User = Structure.new do
  attribute(:name, String)
  attribute(:age, Integer)
end

User.parse(name: "Alice", age: 30) # Works
User.parse(name: nil, age: nil)    # Works, nil values allowed
User.parse(name: "Alice")          # ArgumentError: missing keyword: :age
```

Use `attribute?` to make attributes truly optional. The key can then be omitted entirely.

```ruby
User = Structure.new do
  attribute(:name, String)
  attribute?(:age, Integer)
end

# Now you can omit the optional attribute
User.parse(name: "Bob")            # Works, age defaults to nil

# You still must provide regular attributes
User.parse(age: 10)                # ArgumentError: missing keyword: :name
```

### Default Values

Handle missing data:

```ruby
Config = Structure.new do
  attribute(:timeout, Integer, default: 30)
  attribute(:debug, :boolean, default: false)
end

config = Config.parse({})  # Empty data

config.timeout # => 30
config.debug   # => false
```

### Array Types

Arrays with automatic element coercion:

```ruby
Order = Structure.new do
  attribute(:items, [String])
  attribute(:quantities, [Integer])
  attribute(:flags, [:boolean])
end

order = Order.parse({
  "items" => [123, 456, "hello"],
  "quantities" => ["1", "2", 3.5],
  "flags" => ["true", 0, 1, "false"]
})

order.items      # => ["123", "456", "hello"]
order.quantities # => [1, 2, 3]
order.flags      # => [true, false, true, false]
```

### Nested Objects

Compose structures for complex data:

```ruby
Address = Structure.new do
  attribute(:street, String)
  attribute(:city, String)
end

User = Structure.new do
  attribute(:name, String)
  attribute(:address, Address)
end

user = User.parse({
  "name" => "Alice",
  "address" => {
    "street" => "123 Main St",
    "city" => "Boston"
  }
})

user.name           # => "Alice"
user.address.street # => "123 Main St"
user.address.city   # => "Boston"
```

### Arrays of Objects

Combine array syntax with nested objects:

```ruby
Tag = Structure.new do
  attribute(:name, String)
  attribute(:color, String)
end

Product = Structure.new do
  attribute(:title, String)
  attribute(:tags, [Tag])
end

product = Product.parse({
  "title" => "Laptop",
  "tags" => [
    { "name" => "electronics", "color" => "blue" },
    { "name" => "computers", "color" => "green" }
  ]
})

product.title           # => "Laptop"
product.tags.first.name # => "electronics"
```

### Lazy Resolution

To handle circular dependencies between classes, you can use string class names that are resolved lazily:

```ruby
module MyApp
  Order = Structure.new do
    attribute(:id, String)
    attribute(:items, ["OrderItem"])  # String resolved lazily
    attribute(:customer, "Customer")  # String resolved lazily
  end

  OrderItem = Structure.new do
    attribute(:name, String)
    attribute(:order, "Order")  # Circular reference back to Order
  end

  Customer = Structure.new do
    attribute(:name, String)
    attribute(:orders, ["Order"])  # Circular reference to Order
  end
end

# Works despite circular dependencies
order = MyApp::Order.parse({
  "id" => "123",
  "customer" => { "name" => "Alice" },
  "items" => [{ "name" => "Widget" }]
})

order.customer.name      # => "Alice"
order.items.first.name   # => "Widget"
```

### Custom Transformations

When you need custom logic:

```ruby
Order = Structure.new do
  attribute :price do |value|
    Money.new(value["amount"], value["currency"])
  end
end

order = Order.parse({
  "price" => { "amount" => "29.99", "currency" => "USD" }
})

order.price # => #<Money:0x... @amount="29.99", @currency="USD">
```

### Boolean Conversion

Structure follows Rails-style boolean conversion:

**Truthy values:** `true`, `1`, `"1"`, `"t"`, `"T"`, `"true"`, `"TRUE"`, `"on"`, `"ON"`
**Falsy values:** Everything else (including `false`, `0`, `"0"`, `"false"`, `""`, `nil`)

```ruby
User = Structure.new do
  attribute(:active, :boolean)
end

User.parse(active: "true").active   # => true
User.parse(active: "1").active      # => true
User.parse(active: "false").active  # => false
User.parse(active: "0").active      # => false
User.parse(active: "").active       # => false
```

### Supported Types

Structure supports Ruby's kernel coercion methods like `String(val)`, `Integer(val)`, `Float(val)`, etc., plus:

- `:boolean` - Custom Rails-style boolean conversion
- `[Type]` - Arrays with element coercion
- Custom classes with `.parse` method
- Ruby standard library classes with `.parse`, including:
  - `Date` - Parses date strings
  - `Time` - Parses various time formats
  - `URI` - Parses URLs into URI objects

```ruby
Event = Structure.new do
  attribute(:name, String)
  attribute(:date, Date)
  attribute(:starts_at, Time)
  attribute(:website, URI)
end

event = Event.parse({
  "name" => "RubyConf",
  "date" => "2024-12-25",
  "starts_at" => "2024-12-25T09:00:00-05:00",
  "website" => "https://rubyconf.org"
})

event.date      # => #<Date: 2024-12-25>
event.starts_at # => 2024-12-25 09:00:00 -0500
event.website   # => #<URI::HTTPS https://rubyconf.org>
```

### Custom Types

The type system is flexible. Any object that responds to `.call` (procs, lambdas) or `.parse` (classes) can be used as a type:

```ruby
# Using a lambda for simple transformations
UppercaseString = ->(val) { val.to_s.upcase }

# Using a class with .parse for complex types
class Money
  def self.parse(data)
    return nil unless data
    amount = data.is_a?(Hash) ? data['amount'] : data
    new(amount.to_f)
  end

  def initialize(amount)
    @amount = amount
  end

  attr_reader :amount
end

Product = Structure.new do
  attribute :name, UppercaseString
  attribute :price, Money
end

product = Product.parse({
  "name" => "widget",
  "price" => { "amount" => "19.99" }
})

product.name  # => "WIDGET"
product.price.amount # => 19.99
```

### Self-Referential Types

Build tree structures and other self-referential data:

```ruby
Tree = Structure.new do
  attribute(:id, Integer)
  attribute(:name, String)
  attribute(:children, [:self], default: [])
end

tree = Tree.parse({
  "id" => 1,
  "name" => "Electronics",
  "children" => [
    { "id" => 2, "name" => "Computers" },
    { "id" => 3, "name" => "Phones", "children" => [
      { "id" => 4, "name" => "Smartphones" }
    ]}
  ]
})

tree.name                           # => "Electronics"
tree.children.first.name            # => "Computers"
tree.children[1].children.first.name # => "Smartphones"
```

Use `:self` for single references or `[:self]` for arrays of self-references. Perfect for modeling hierarchical data like navigation menus, comment threads, or organizational charts.

### After Parse Callbacks

Add validation or post-processing logic that runs after parsing:

```ruby
Order = Structure.new do
  attribute(:order_id, String)
  attribute(:total, Float)

  after_parse do |order|
    raise "Order ID is required" if order.order_id.nil?
    raise "Total must be positive" if order.total && order.total <= 0
  end
end

# Raises error for invalid data
Order.parse(total: -10)  # => RuntimeError: Total must be positive

# Works fine with valid data
order = Order.parse(order_id: "123", total: 99.99)
order.order_id  # => "123"
```

The `after_parse` callback receives the parsed instance and runs after all attributes have been coerced. Any exception raised prevents the instance from being returned.

### RBS Type Signatures

Generate RBS type signatures for your Structure classes:

```ruby
require 'structure/rbs'

User = Structure.new do
  attribute(:name, String)
  attribute(:age, Integer)
  attribute(:tags, [String])
end

# Generate RBS content
Structure::RBS.emit(User)
# => class User < Data
#      def self.new: (name: String?, age: Integer?, tags: Array[String]?) -> instance
#      def self.parse: (?(Hash[String | Symbol, untyped]), **untyped) -> instance
#      attr_reader name: String?
#      attr_reader age: Integer?
#      attr_reader tags: Array[String]?
#      ...
#    end

# Write RBS to file
Structure::RBS.write(User, dir: "sig")  # => "sig/user.rbs"
```

## Development

```bash
$ bundle install
$ bundle exec rake
```

### Performance Considerations

String-based method generation with `class_eval` is more performant but also overcomplicates the code. For now, I prioritize legibility.
