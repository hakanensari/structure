# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png)](http://travis-ci.org/hakanensari/structure)

Structure is a typed, nestable key/value container.

It will shine in the ephemeral landscape of API-backed data.

    require 'structure'

    class Person < Structure
      key  :name
      one  :location, Location
      many :friends,  Person
    end

    class Location < Structure
      key :lon, Float
      key :lat, Float
    end

Please see [the project page] [1] for more detailed info.

[1]: http://code.papercavalier.com/structure/
