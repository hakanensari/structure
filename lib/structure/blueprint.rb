class Structure
  # Internal: A hash that stores default attribute values.
  class Blueprint
    include Enumerable

    # Singleton classes are not dupable.
    SINGLETON_CLASSES = [
      NilClass, TrueClass, FalseClass, Numeric, Symbol
    ].freeze

    # Creates a new blueprint.
    def initialize
      @table = {}
    end

    # Adds a default value for a given attribute.
    #
    # key - The Symbol name of the attribute.
    # val - The default value of the attribute. This can be a Proc which would
    #       be called when the blueprinted object is created.
    #
    # Returns nothing.
    def add(key, val)
      return unless val

      @table[key] = case val
                    when Proc
                      val
                    when *SINGLETON_CLASSES
                      -> { val }
                    else
                      -> { val.dup }
                    end
    end

    # Yields pairs of keys and their default values.
    def each
      @table.each { |k, v| yield [k, v[]] }
    end

    # Returns a hash of keys and default values.
    def to_h
      reduce({}) { |a, (k, v)| a.merge k => v }
    end

    private

    def initialize_copy(orig)
      super
      @table = @table.dup
    end
  end
end
