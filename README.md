# Structure

[![travis][1]][2]

Structure is a nestable, coercible, Hash-like data structure that weighs just
over 200 sloc.

![structure][3]

## Installation

```bash
gem install structure --pre
```

or in your **Gemfile**

```ruby
gem 'structure', '~> 1.0.0.pre'
```

## Anonymous Structures

An anonymous structure resembles an [OpenStruct][4], with the added benefit of being recursive.

```ruby
company = Structure.new name: 'Hipster Sweatshop',
                        address: {
                          street: '87 Richardson St',
                          city:   'Brooklyn'
                          zip:    11222 }
                          
puts company.address.city # => "Brooklyn"
```

## Named Structures

A named Structure allows the possibility to define attributes on the class
level and coerce their data types.

```ruby
class Person < Structure
  attribute :name, String
  attribute :age, Integer
end
```

Alternatively, coerce values with procs:

```ruby
class Post < Structure
  attribute :title, lambda &:capitalize
  attribute :created_at, default: -> { Time.now }
end

post = Post.new title: 'hello world'
puts post.title # => "Hello World"
puts post.created_at # => "2012-01-01 12:00:00 +0000"
```

The obligatory syntactic sugar:

```ruby
class Book < Structure
  one :publisher, Publisher
  many :authors, Author
end

class Publisher < Structure
  key :name, String
end

class Author < Structure
  key :name, String
end
```

Structures are meant to be ephemeral. They translate to and from JSON
seamlessly, which means you can marshal a structure into JSON and then read it
back into your application on another machine.

It's a breeze to extend structures with ActiveModel modules.

[1]: https://secure.travis-ci.org/hakanensari/structure.png
[2]: http://travis-ci.org/hakanensari/structure
[3]: http://f.cl.ly/items/2u2v0e3k2I3w1A0y2e25/ruby.png
[4]: http://ruby-doc.org/stdlib-1.9.3/libdoc/ostruct/rdoc/OpenStruct.html
