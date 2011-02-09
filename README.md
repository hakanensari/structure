Structure
=========

Structure is a nested OpenStruct implementation. Or, recursively put, Structure is a truly OpenStruct OpenStruct.

    require 'structure'
    
    source = {
      :title => 'Mille Plateaux',
      :authors => [
        {
          :name => "Deleuze",
        }
      ],
      :publisher => {
        :name => "Minuit",
    }
    
    book = Structure.new(source)
    
    puts book.authors.first.name
    => "Deleuze"
    
    puts book.publisher.name
    => "Minuit"
