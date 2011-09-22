begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

class Structure
  # Builds a structure out of its JSON representation.
  def self.json_create(hsh)
    hsh.delete('json_class')
    new(hsh)
  end

  # Converts structure to its JSON representation.
  def to_json(*args)
    { JSON.create_id => self.class.name }.
      merge(attributes).
      to_json(*args)
  end
end

require 'structure/ext/active_support' if defined?(Rails)
