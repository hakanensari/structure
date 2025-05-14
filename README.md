# Structure

[![Build](https://github.com/hakanensari/structure/workflows/build/badge.svg)](https://github.com/hakanensari/structure/actions)

Structure is a lightweight Ruby library that helps you transform raw data into clean objects with thread-safe, lazily evaluated attributes.

## Why Use Structure?

When working with external APIs, you often get back complex nested hashes that are cumbersome to work with directly:

```ruby
# Without Structure - messy and repetitive
product_title = response_data["Items"]["Item"]["ItemAttributes"]["Title"]
product_price = Money.new(response_data["Items"]["Item"]["Price"]["Amount"].to_f * 100, response_data["Items"]["Item"]["Price"]["CurrencyCode"])
if response_data["Items"]["Item"]["IsEligibleForPrime"] == "1"
  # Do something...
end
```

Structure provides a cleaner, more object-oriented approach:

```ruby
# With Structure - clean and maintainable
product.title
product.price
if product.prime_eligible?
  # Do something...
end
```

## Key Features

- **Lazy Evaluation** - Attributes are computed only when accessed
- **Thread Safety** - All attribute access is synchronized with a mutex
- **Immutability Support** - Works well with frozen objects
- **Minimal Overhead** - Zero runtime dependencies
- **Simple API** - Easy to understand and use
- **Marshaling Support** - Fully compatible with Ruby's Marshal

## Installation

Add to your Gemfile:

```ruby
gem "structure"
```

Or install directly:

```
$ gem install structure
```

## Basic Usage

### Defining a Structure

```ruby
class Product
  include Structure

  attribute(:id) { data["id"] }
  attribute(:name) { data["name"] }
  attribute(:price) { BigDecimal(data["price_cents"]) / 100 }
  attribute(:available?) { data["in_stock"] }

  private

  attr_reader :data

  def initialize(data)
    @data = data
  end
end

# Usage
product = Product.new({ "id" => "123", "name" => "Ruby Mug", "price_cents" => "1295", "in_stock" => true })
product.name        # => "Ruby Mug"
product.price       # => 12.95
product.available?  # => true
```

### Real-World Example: Amazon Selling Partner API

```ruby
class AmazonProduct
  include Structure

  attribute(:asin) { data['identifiers']['marketplaceASIN']['ASIN'] }
  attribute(:marketplace_id) { data['identifiers']['marketplaceASIN']['MarketplaceId'] }
  attribute(:title) { attributes_data['title'] }
  attribute(:brand) { attributes_data['brand'] }

  # Complex nested data parsing
  attribute(:price) do
    raw = summaries_data.dig('price', 'amount', 'amount')
    raw ? BigDecimal(raw) : nil
  end

  attribute(:currency) do
    summaries_data.dig('price', 'amount', 'currencyCode')
  end

  # Computed property combining multiple attributes
  attribute(:offer_url) do
    "https://#{marketplace_url}/dp/#{asin}"
  end

  private

  attr_reader :data

  def initialize(item_data)
    @data = item_data
  end

  def attributes_data
    @attributes_data ||= data['attributes'] || {}
  end

  def summaries_data
    @summaries_data ||= data['summaries'] || {}
  end

  def marketplace_url
    case marketplace_id
    when 'ATVPDKIKX0DER' then 'amazon.com'
    when 'A1F83G8C2ARO7P' then 'amazon.co.uk'
    else "amazon.com"
    end
  end
end
```

## Advanced Features

### Thread Safety

All attribute access is protected by a mutex, making Structure objects safe to use in multi-threaded environments:

```ruby
# This is safe across multiple threads
threads = 10.times.map do
  Thread.new { product.price }
end
```

### Serialization

Convert your objects back to hash representations:

```ruby
product.to_h  # => {"id"=>"123", "name"=>"Ruby Mug", "price"=>12.95, "available"=>true}
```

### Working with Collections

Use with collections of items:

```ruby
class SearchResults
  include Structure

  attribute(:total_count) { data['meta']['total_count'] }
  attribute(:page) { data['meta']['page'] }

  attribute(:products) do
    data['items'].map { |item_data| Product.new(item_data) }
  end

  private

  attr_reader :data

  def initialize(data)
    @data = data
  end
end

# Usage
results = SearchResults.new(api_response)
results.total_count  # => 243
results.products.each do |product|
  puts "#{product.name}: #{product.price}"
end
```

### Inheritance

Structure works well with class inheritance:

```ruby
class Book < Product
  attribute(:author) { data['author'] }
  attribute(:pages) { data['page_count'].to_i }
end
```

## Comparison with Alternatives

| Feature         | Structure | OpenStruct | Dry::Struct | Plain Hash |
| --------------- | --------- | ---------- | ----------- | ---------- |
| Lazy Evaluation | ✅        | ❌         | ❌          | ❌         |
| Thread Safety   | ✅        | ❌         | ❌          | ❌         |
| Type Coercion   | Manual    | ❌         | ✅          | ❌         |
| Performance     | Good      | Poor       | Good        | Excellent  |
| Dependencies    | None      | stdlib     | Multiple    | None       |
| Immutability    | ✅        | Limited    | ✅          | Limited    |

## Development

```
$ bundle install
$ rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
