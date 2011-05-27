class Person < Structure
  key :name
  key :age, :type => Integer
  key :friends, :type => Array, :default => []
end
