class Person < Structure
  key :name
  key :age, :type => Integer
  embeds_many :friends
end
