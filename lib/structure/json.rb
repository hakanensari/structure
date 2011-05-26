unless Object.const_defined?(:JSON) and ::JSON.const_defined?(:JSON_LOADED) and
  ::JSON::JSON_LOADED
  require 'json'
end

class Structure
  def self.json_create(object)
    object.delete('json_class')
    new(object)
  end

  def to_json(*args)
    klass = self.class.name
    { JSON.create_id => klass }.
      merge(@attributes).
      to_json(*args)
  end
end
