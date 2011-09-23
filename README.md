# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png?branch=master)](http://travis-ci.org/hakanensari/structure)

Structure is a typed, nestable key/value container.

    class Person < Structure
      key  :name
      many :friends, Person
    end

Please see the [wiki] [1] for more detail.

[1]: https://github.com/hakanensari/structure/wiki/
