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

if defined? ActiveSupport
  class Structure
    def as_json(options = nil)
      # create a subset of the attributes by applying :only or :except
      subset = if options
        if attrs = options[:only]
          @attributes.slice(*Array.wrap(attrs))
        elsif attrs = options[:except]
          @attributes.except(*Array.wrap(attrs))
        else
          @attributes.dup
        end
      else
        @attributes.dup
      end

      klass = self.class.name
      { JSON.create_id => klass }.
        merge(subset)
    end
  end
end
