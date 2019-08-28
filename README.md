# Structure

[![CircleCI](https://circleci.com/gh/hakanensari/structure.svg?style=svg)](https://circleci.com/gh/hakanensari/structure)

Structure helps you encapsulate data parsing in an immutable value object.

[See here](https://github.com/hakanensari/mws-orders) for how I use it.

## Usage

This is a contrived example:

```ruby
class Name
  include Structure

  SEPARATOR = " "

  def initialize(data)
    @data = data
  end

  attribute :first do
    @data.first
  end

  attribute :last do
    @data.last
  end

  attribute :middle do
    @data[1...-1].join(SEPARATOR) if @data.size > 2
  end

  def full
    [first, middle, last].compact.join(SEPARATOR)
  end
end

name = Name.new(%w(Johann Sebastian Bach))
# => #<Name first="Johann", middle="Sebastian", last="Bach">
name.first
# => "Johann"
name.full
# => "Johann Sebastian Bach"
name.attributes
# => {"first"=>"Johann", "middle"=>"Sebastian", "last"=>"Bach"}
```

When testing, use `.double`. This will cast the parser to an object that mocks the public interface.

```ruby
require "structure/double"

name = Name.double.new(first: "Johann", middle: "Sebastian", last: "Bach")
# => #<Name first="Johann", middle="Sebastian", last="Bach">
name.first
# => "Johann"
name.full
# => "Johann Sebastian Bach"
name.attributes
# => {"first"=>"Johann", "middle"=>"Sebastian", "last"=>"Bach"}
```
