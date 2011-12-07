class Structure
  module Ext
    module ActiveSupport
      def as_json(options = nil)
        subset = if options
          if only = options[:only]
            marshal_dump.slice(*Array.wrap(only))
          elsif except = options[:except]
            marshal_dump.except(*Array.wrap(except))
          else
            marshal_dump
          end
        else
          marshal_dump
        end

        { JSON.create_id => self.class.name }.
          merge(subset)
      end
    end
  end
end
