class Book < Structure
  key :title
  key :authors, Array, :value => []
end
