# Structure

[![Travis](https://travis-ci.org/hakanensari/structure.svg)](https://travis-ci.org/hakanensari/structure)

<img src="http://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Structure_Paris_les_Halles.jpg/320px-Structure_Paris_les_Halles.jpg" align="right" alt="Structure">

Structure is a mixin that helps you write clean, immutable value objects when parsing data in Ruby.

My typical use case is when parsing XML documents—your mileage may vary.

Structure also pretty-inspects the data it stores, which really helps when working in the command line, and comes with a helper to mock when testing.

It should work seamlessly with the various ActiveModel mixins out there.

## Usage

A contrived example:

```ruby
class Name
  include Structure

  SEPARATOR = " "

  def initialize(full)
    @names = full.split(SEPARATOR)
  end

  attribute :first do
    @names.first
  end

  attribute :last do
    @names.last
  end

  attribute :middle do
    @names[1...-1].join(SEPARATOR)
  end

  def full
    [first, middle, last].join(SEPARATOR)
  end
end

name = Name.new("Johann Sebastian Bach")
name.first # => "Johann"
name # => #<Name first="Johann", middle="Sebastian", last="Bach">
name.attributes # => {"first"=>"Johann", "middle"=>"Sebastian", "last"=>"Bach"}
```

To mock when testing, use `.double`. This will cast the parser to an object that mimics the former's public interface but replaces the original parsing implementation with an initializer that populates the attributes with a hash.

```ruby
require "structure/double"
name = Name.double.new(first: 'Johann', middle: "Sebastian", last: "Bach")
name.first # => "Johann"
```
