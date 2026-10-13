# frozen_string_literal: true

require "set"

module Structure
  # Type coercion methods for converting values to specific types
  module Types
    class << self
      # Rails-style boolean truthy values
      # Reference: https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html
      BOOLEAN_TRUTHY = Set.new([true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"]).freeze
      private_constant :BOOLEAN_TRUTHY

      # Main factory method for creating type coercers
      #
      # @param type [Class, Symbol, Array, String, nil] Type specification
      # @param context [Class, nil] Context class for lazy-loading and self-referential types
      # @return [Proc, nil] Coercion proc or nil if no coercion needed
      # @raise [ArgumentError] If type is a Hash instance (typed hashes not yet supported) or unsupported type
      #
      # @example Boolean type
      #   coerce(:boolean) # => boolean proc
      #
      # @example Self-referential types
      #   coerce(:self) # => proc that calls context.parse
      #
      # @example Kernel types
      #   coerce(Integer) # => proc that calls Kernel.Integer
      #
      # @example Array types
      #   coerce([String]) # => proc that coerces array elements to String
      #
      # @example Parseable types
      #   coerce(Date) # => proc that calls Date.parse
      #
      # @example No coercion
      #   coerce(nil) # => nil
      #
      # @example Custom lambdas
      #   coerce(->(val) { val.upcase }) # => returns the lambda itself
      #
      # @example Lazy-resolved classes
      #   coerce("MyClass") # => proc that resolves and coerces to MyClass
      def coerce(type, context = nil)
        case type
        when :boolean
          boolean
        when :self
          self_referential(context)
        when ->(t) { t.respond_to?(:name) && t.name && Kernel.respond_to?(t.name) }
          kernel(type)
        when ->(t) { t.is_a?(Array) && t.length == 1 }
          array(type.first, context)
        when ->(t) { t.respond_to?(:parse) }
          parseable(type)
        when nil
          type
        when ->(t) { t.respond_to?(:call) }
          type
        when String
          lazy_class(type, context)
        else
          raise ArgumentError, "cannot specify #{type.inspect} as type"
        end
      end

      # Makes an object shareable when Ruby can. A lambda that closes over a caller's unshareable object can't be,
      # and comes back as it is. Where Ruby has no Ractor, nothing is shared.
      if defined?(Ractor)
        # @api private
        def shareable(object)
          Ractor.make_shareable(object)
        rescue Ractor::IsolationError
          object
        end
      else
        # @api private
        def shareable(object)
          object
        end
      end

      private

      def boolean
        @boolean ||= shareable(->(val) { BOOLEAN_TRUTHY.include?(val) })
      end

      def self_referential(context)
        shareable(->(val) { context.parse(val) })
      end

      def lazy_class(class_name, context)
        key = shareable(Object.new)
        shareable(->(value) { parse_as(resolved_class(key, class_name, context), value) })
      end

      def array(element_type, context = nil)
        coercion = case element_type
        when :self
          lambda do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            value.map { |element| context.parse(element) }
          end
        when String
          key = shareable(Object.new)
          lambda do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            element_class = resolved_class(key, element_type, context)
            value.map { |element| parse_as(element_class, element) }
          end
        else
          element_coercer = coerce(element_type, context)
          lambda do |value|
            unless value.respond_to?(:map)
              raise TypeError, "can't convert #{value.class} into Array"
            end

            value.map { |element| element_coercer.call(element) }
          end
        end

        shareable(coercion)
      end

      def parseable(type)
        @parseable_cache ||= {} # : Hash[untyped, Proc]
        @parseable_cache[type] ||= shareable(->(val) { parse_as(type, val) })
      end

      # A method must make this call, not a lambda. A parser written in C, such as Date.parse, keeps its match in
      # the caller's $~, and a lambda shared between Ractors shares its $~ too.
      def parse_as(type, val)
        type.parse(val)
      end

      def kernel(type)
        @kernel_cache ||= {} # : Hash[untyped, Proc]
        @kernel_cache[type] ||= shareable(->(val) { Kernel.send(type.name, val) })
      end

      # Resolves a class given by name once in each Ractor. A shareable lambda can't keep the class itself, so it
      # keeps a key into a weak map in the Ractor's local storage. Where Ruby has no Ractor, the key keeps the class.
      if defined?(Ractor)
        def resolved_class(key, class_name, context)
          classes = Ractor.current[:__structure_classes__] ||= ObjectSpace::WeakMap.new # steep:ignore
          classes[key] ||= resolve_class(class_name, context)
        end
      else
        def resolved_class(key, class_name, context)
          key.instance_variable_get(:@resolved) ||
            key.instance_variable_set(:@resolved, resolve_class(class_name, context))
        end
      end

      def resolve_class(class_name, context)
        if context && defined?(context.name)
          namespace = context.name.to_s.split("::")[0...-1]
          if namespace.any?
            begin
              namespace.reduce(Object) { |mod, name| mod.const_get(name) }.const_get(class_name)
            rescue NameError
              Object.const_get(class_name)
            end
          else
            Object.const_get(class_name)
          end
        else
          Object.const_get(class_name)
        end
      rescue NameError => e
        raise NameError, "Unable to resolve class '#{class_name}': #{e.message}"
      end
    end
  end
end
