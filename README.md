# Structure

[![Travis](https://travis-ci.org/hakanensari/structure.svg)](https://travis-ci.org/hakanensari/structure)

Structure helps you write clean parsers that behave like immutable value objects.

## Usage

The following example wraps a JSON string:

```ruby
require 'json'

class User
  include Structure

  def initialize(data)
    @data = data
  end

  attribute :name do
    fetch('name')
  end

  attribute :age do
    fetch('age').to_i
  end

  attribute :admin? do
    fetch('admin')
  end

  def adult?
    age >= 18
  end

  # Implement heavy-duty parsing action below

  private

  def fetch(key)
    parsed_data.fetch(key)
  end

  def parsed_data
    @parsed_data ||= parse_data
  end

  def parse_data
    JSON.parse(@data)
  end
end
```

Usage follows familiar idioms so should be self-explanatory:

```ruby
user = User.new('{"name":"Jane","age":18,"admin":true}')

# A read-only, memoised attribute
user.name # => "Jane"

# Cast all attributes to a Hash
user.attributes # => {"name"=>"Jane", "admin" =>true}

# Bonus: Pretty-inspect in REPL
puts user # => #<User name="Jane", admin=true>
```

To ease testing objects the parser collaborates in, I have added the class method `.double`. This casts the parser to an object that mimics the former's public interface but replaces the original parsing implementation with an initialiser that accepts a hash and populates the corresponding attributes:

```ruby
user = User.double.new(name: 'Jane', age: 18, admin: false)

user.name => "Jane"
user.adult? => true
```
