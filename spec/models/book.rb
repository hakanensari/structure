class Book < Structure
  key :title
  key :authors, :type => Array, :value => []
end
