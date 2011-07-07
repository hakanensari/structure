require 'structure/static'

class City < Structure
  include Static

  set_data_path File.expand_path("../../fixtures/cities.yml", __FILE__)

  key :name
end
