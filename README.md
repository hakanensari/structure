# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png?branch=master)](http://travis-ci.org/hakanensari/structure)

Structure is a typed key/value container.

    class Person < Structure
      key :name
      key :friends, Array, []
    end

Please see the [wiki] [1] for more detail.

[1]: https://github.com/hakanensari/structure/wiki/
