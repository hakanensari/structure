class Person < Structure
  key :name
  key :age, :type => Integer
  key :website, :type => URI
  has_many :friends
end
