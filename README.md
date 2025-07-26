# Structure

[![CI/CD Pipeline](https://github.com/hakanensari/structure/actions/workflows/ci.yml/badge.svg)](https://github.com/hakanensari/structure/actions/workflows/ci.yml)

**📦 Structure your data!**

Turn unruly hashes into clean, immutable Ruby Data objects with type coercion.

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

Built on the Ruby Data class for immutability, pattern matching, and all the other good stuff. Zero dependencies.

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

### Custom Transformations

When you need custom logic:

```ruby
Order = Structure.new do
  attribute(:total, from: "OrderTotal") do |data|
    amount = data["Amount"]
    currency = data["CurrencyCode"]
    "#{amount} #{currency}"
  end
end

order = Order.parse({
  "OrderTotal" => { "Amount" => "29.99", "CurrencyCode" => "USD" }
})

order.total # => "29.99 USD"
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
- Ruby standard library classes with `.parse`:
  - `Date` - Parses date strings
  - `DateTime` - Parses ISO 8601 datetime strings
  - `Time` - Parses various time formats
  - `URI` - Parses URLs into URI objects

```ruby
Event = Structure.new do
  attribute(:name, String)
  attribute(:date, Date)
  attribute(:starts_at, DateTime)
  attribute(:created_at, Time)
  attribute(:website, URI)
end

event = Event.parse({
  "name" => "RubyConf",
  "date" => "2024-12-25",
  "starts_at" => "2024-12-25T09:00:00-05:00",
  "created_at" => "2024-01-15 10:30:00",
  "website" => "https://rubyconf.org"
})

event.date       # => #<Date: 2024-12-25>
event.starts_at  # => #<DateTime: 2024-12-25T09:00:00-05:00>
event.created_at # => 2024-01-15 10:30:00 +0100
event.website    # => #<URI::HTTPS https://rubyconf.org>
```

## Development

```bash
$ bundle install
$ rake test
```
