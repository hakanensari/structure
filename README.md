# Structure

[![CircleCI](https://circleci.com/gh/hakanensari/structure.svg?style=svg)](https://circleci.com/gh/hakanensari/structure)

Structure is a tiny library that helps you lazy parse data into thread-safe, memoized attributes.

```ruby
class Random
  include Structure

  attribute :value do
    sleep rand
    rand
  end
end
```
