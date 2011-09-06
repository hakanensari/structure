class Structure
  # Converts structure to a JSON representation.
  def as_json(options = nil)
    subset = if options
      if only = options[:only]
        attributes.slice(*Array.wrap(only))
      elsif except = options[:except]
        attributes.except(*Array.wrap(except))
      else
        attributes.dup
      end
    else
      attributes.dup
    end

    { JSON.create_id => self.class.name }.
      merge(subset)
  end
end
