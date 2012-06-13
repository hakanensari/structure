# Structure

[![travis][1]][2]

Structure is a Ruby data structure that weighs just over 200 sloc.

![structure][3]

## Installation

```bash
gem install structure
```

or in your **Gemfile**

```ruby
gem 'structure', '~> 1.0.pre'
```

## Examples

Anonymous structures resemble [OpenStruct][4]:

```ruby
record = Structure.new
record.name = "John Smith"

puts record.name => "John Smith"
puts record.address => nil
```

Structures are recursive:

```ruby
hash = {
  "name"       => "Australia",
  "population" => "20000000",
  "cities"     => [
    {
      "name"       => "Sydney",
      "population" => "4100000"
    },
    {
      "name"       => "Melbourne",
      "population" => "4000000"
    }
  ]
}

country = Structure.new hash
puts country.name              => "Australia"
puts country.cities.first.name => "Sydney"
```

Named structures can define attributes:

```ruby
require 'money'

class Product < Structure
  attribute :cents, Integer
  attribute :currency, String, default: "USD"

  def price
    Money.new cents, currency
  end
end

product = Product.new cents: "100"
puts product.price # => #<Money cents:100 currency:USD>
```

Attributes can optionally coerce type or otherwise format their values.

```ruby
class Book < Structure
  attribute :title, lambda &:capitalize
  attribute :created_at, String, default: lambda { Time.now.to_s }
end

book = Book.new(title: "a thousand plateaus")
puts product.sku # => "A Thousand Plateaus"
puts product.created_at # => "2012-01-01 12:00:00 +0000"
```

Structures speak JSON fluently, which should come handy when talking to APIs or
handling other ephemeral data.

[1]: https://secure.travis-ci.org/hakanensari/structure.png
[2]: http://travis-ci.org/hakanensari/structure
[3]: http://f.cl.ly/items/2u2v0e3k2I3w1A0y2e25/ruby.png
[4]: http://ruby-doc.org/stdlib-1.9.3/libdoc/ostruct/rdoc/OpenStruct.html
