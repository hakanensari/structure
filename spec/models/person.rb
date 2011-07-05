class Person < Structure
  key :name
  key :age, Integer
  embeds_many :friends
end
