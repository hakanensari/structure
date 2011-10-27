begin
  JSON::JSON_LOADED
rescue NameError
  require 'json'
end

class Structure
  # JSON methods for a structure
  #
  # Include this in your structure if you need to cast it to JSON and
  # vice versa.
  #
  # @example
  #   class Point < Structure
  #     include JSON
  #
  #     key :x, Integer
  #     key :y, Integer
  #   end
  #
  # Alternatively, include it in the parent class if you have more than
  # one structure.
  #
  # @example
  #   class Structure
  #     include JSON
  #   end
  #
  module JSON
    def self.included(base)
      base.extend ClassMethods
    end

    # Converts structure to its JSON representation
    #
    # @param [Hash] args
    # @return [JSON] a JSON representation of the structure
    def to_json(*args)
      { ::JSON.create_id => self.class.name }.
        merge(@attributes).
        to_json(*args)
    end

    if defined? ActiveSupport
      # Converts structure to its JSON representation
      #
      # @param [Hash] options
      # @return [JSON] a JSON representation of the structure
      def as_json(options = nil)
        subset = if options
          if only = options[:only]
            @attributes.slice(*Array.wrap(only))
          elsif except = options[:except]
            @attributes.except(*Array.wrap(except))
          else
            @attributes.dup
          end
        else
          @attributes.dup
        end

        { ::JSON.create_id => self.class.name }.
          merge(subset)
      end
    end

    module ClassMethods
      # Builds a structure out of its JSON representation
      #
      # @param [Hash] hsh a hash representation of a JSON
      # @return [Structure] a structure
      def json_create(hsh)
        hsh.delete('json_class')

        new(hsh)
      end
    end
  end
end
