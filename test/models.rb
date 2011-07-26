class Book
  include Structure

  key :title
  key :authors, Array, :value => []
end


