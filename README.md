# Structure

Value objects in Ruby

## Usage

```ruby
class Location
  include Structure

  attr :res

  def initialize(res)
    @res = res
  end

  value :latitude do
    res.fetch(:lat)
  end

  value :longitude do
    res.fetch(:lng)
  end
end

location = Location.new(lat: 10, lng: 100)
location.to_h # {:latitude=>10, :longitude=>100}
```
