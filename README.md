# Structure

[![travis](https://secure.travis-ci.org/hakanensari/structure.png?branch=master)](http://travis-ci.org/hakanensari/structure)

Structure is a somewhat modernised OpenStruct, best for producing and
consuming ephemeral data across APIs.

    person = Structure.new :name => 'John',
                           :friends => [{ :name => 'Jane' }]

    puts person.friends.first.name
    # => "Jane"
    puts JSON.parse(person.to_json).friends.first.name
    # => "Jane"
