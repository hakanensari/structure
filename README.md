# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png)](http://travis-ci.org/hakanensari/structure)

Structure is a typed, nestable, ephemeral key/value container.

## Usage

Install and require the gem.

    require 'structure'

Define a model.

    Document = Structure::Document

    class Person < Document
      key  :name
      many :friends, :class_name => 'Person'
    end

    person = Person.create(:name => 'John')
    person.friends << Person.create(:name => 'Jane')
    person.friends.size # 1

Please see [the project page] [1] for more detailed info.

[1]: http://code.papercavalier.com/structure/
