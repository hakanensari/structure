class Structure
  # Internal: Coercion builder.
  #
  # A coercion in Structure is a block of code that type-converts a given
  # value. The simplest coercion would be `->(v) { v }`, which returns a
  # value as is.
  module Coercion
    # The default coercion recursively casts hashes into structures.
    STRUCTURE = ->(val) {
      case val
      when Hash
        Structure.new val
      when Array
        val.map &STRUCTURE
      else
        val
      end
    }

    # Builds a coercion.
    #
    # coercion - A Class to typecast a value with or a Proc that defines a
    #            coercion (default: nil).
    #
    # Returns a Proc coercion.
    #
    # Raises a Type Error if a coercion is not valid.
    def self.build(coercion = nil)
      case coercion
      when nil
        STRUCTURE
      when Class
        if Kernel.respond_to? mth = coercion.to_s.to_sym
          ->(v) { Kernel.send mth, v }
        else
          ->(v) {
            unless v.is_a?(coercion)
              raise TypeError, "#{v} isn't a #{coercion}"
            end
            v
          }
        end
      when Proc
        coercion
      else
        raise TypeError, "#{coercion} isn't a coercion"
      end
    end
  end
end
