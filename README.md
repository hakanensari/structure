# Structure

Structure is a Struct-like key/value container.

[![travis](https://secure.travis-ci.org/hakanensari/structure.png)](http://travis-ci.org/hakanensari/structure)

## Usage

Set up a model:

    require 'structure'

    class Person < Structure
      key  :name
      many :friends
    end

Do things with it:

    person = Person.new
    friend = Person.new
    person.friends << friend
    puts person.to_json
    => {"json_class":"Person","name":null,"friends":[{"json_class":"Person","name":null,"friends":[]}]}

Please see [the project page] [1] for more detailed info.

[1]: http://code.papercavalier.com/structure/
