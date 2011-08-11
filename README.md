# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png)](http://travis-ci.org/hakanensari/structure)

Structure is a Struct-like key/value container.

    require 'structure'

    class Person < Structure
      key  :name
      many :friends
    end

Please see [the project page] [1] for more detailed info.

[1]: http://code.papercavalier.com/structure/
