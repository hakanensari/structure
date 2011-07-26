# Structure

[![travis](https://secure.travis-ci.org/papercavalier/structure.png)](http://travis-ci.org/papercavalier/structure)

Structure is Ruby module that turns a class into a key/value container.

## Usage

Set up models.

```ruby
require 'structure'

class Book
  include Structure

  attribute   :title
  attribute   :binding, :default => "Hardcover"
  attribute   :year_published, Integer
  embeds_many :authors
end

class Author
  include Structure

  attribute :name
  attribute :role
end
```

Create some objects.

```ruby
book = Book.new :title => "A Thousand Plateaus"
author = Author.new :name => "Gilles Deleuze"
book.authors << author
```

Attributes in structures are typecasted.

```ruby
book.year_published = "1985"
puts book.year_published
=> 1985
```

Translate to JSON and back into Ruby.

```ruby
json = book.to_json
puts json
=> {"json_class":"Book","title":"A Thousand Plateaus","binding":"Hardcover,"year_published":1985,"authors":[{"json_class":"Author","name":"Gilles Deleuze","role":null}]}

book = JSON.parse(json)
puts book.authors.first.name
=> "Gilles Deleuze"
```

Mix in Active Model modules.

```ruby
require 'active_model'

class Book
  include ActiveModel::Validations

  validates_presence_of :title
end

book = Book.new
book.valid?
=> false
book.errors
=> {:title=>["can't be blank"]}
```
