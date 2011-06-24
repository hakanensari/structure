class Person < Structure
  key :name
  key :age, :type => Integer
  has_many :friends
end
