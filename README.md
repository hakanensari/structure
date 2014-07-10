# Structure

[![Travis](https://travis-ci.org/hakanensari/structure.svg)](https://travis-ci.org/hakanensari/structure)

Structure is minimal glue that helps you parse data into immutable value objects.

```ruby
class Person
  include Structure

  def initialize(data)
    @data = data
  end

  attribute :name do
    parse(:name)
  end

  private

  def parse(key)
    # Heavy-duty parsing action on @data
  end
end

person = Person.new(data)

# Bonus 1: Pretty-inspects in REPL
puts person

# Bonus 2: Returns all attributes as a Ruby Hash
person.attributes

# Bonus 3: Builds a double for testing collaborated objects
Person.to_struct.new(name: 'Jane')
```
