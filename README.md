# Structure

[![travis][1]][2]

![structure][3]

Structure is a key/value container.

## Installation

```bash
gem install structure
```

or in your **Gemfile**

```ruby
gem 'structure', '~> 1.0.pre'
```

## Examples

On the most basic level, Structure behaves like an OpenStruct:

```ruby
person = Structure.new
person.name = "John Smith"

puts person.name => "John Smith"
```

You can build anonymous structures recursively:

```ruby
hash = {
  "name"   => "Australia",
  "cities" => [
    {
      "name" => "Sydney",
    },
    {
      "name" => "Melbourne",
    }
  ]
}

country = Structure.new hash
puts country.name              => "Australia"
puts country.cities.first.name => "Sydney"
```

It's also possible to define structured documents and define attributes with
coerced types and default values:

```ruby
class Price < Structure
  attribute :cents, Integer
  attribute :currency, String, default: "USD"
end

hash = { "cents" => "100" }
price = Price.new hash
puts price.cents    => 100
puts price.currency => "USD"
```

You can assign dynamic default values:

```ruby
class Product < Structure
  now = lambda { Time.now.to_s }

  attribute :sku, lambda(&:upcase)
  attribute :created_at, String, default: now
end

product = Product.new(:sku => 'abc')
puts product.sku => "ABC"
puts product.created_at => "2012-01-01 12:00:00 +0000"
```

[1]: https://secure.travis-ci.org/hakanensari/structure.png
[2]: http://travis-ci.org/hakanensari/structure
[3]: http://f.cl.ly/items/2u2v0e3k2I3w1A0y2e25/ruby.png

