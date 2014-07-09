# Structure

Structure is minimal glue that helps you parse data&mdash;for instance, API responses&mdash;into immutable value objects.

## Usage

Usage is straightforward. Mix in the module and define the parser methods with `.attribute`, a naming convention I decided to stick to.

```ruby
class Location
  include Structure

  def initialize(data)
    @data = data
  end

  attribute :latitude do
    parse(:latitude)
  end

  attribute :longitude do
    parse(:longitude)
  end

  private

  def parse(key)
    # Heavy-duty parsing action on @data
  end
end
```

Once you have your parser defined, initialise it with some data and take it to a drive.

```ruby
location = Location.new(data)
puts location.latitude # => Some latitude
puts location.to_h # => All attributes as a Ruby Hash
puts location # => Bonus: This will pretty-inspect the instance
```

When testing objects the parser collaborates in, you may benefit from a double to stand in for the real parser.

```ruby
double = Location.to_struct.new(location: 10, latitude: 10)
```
