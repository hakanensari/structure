# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compiler)

module Tapioca
  module Dsl
    module Compilers
      # Generates RBI files for Structure-based Data classes.
      #
      # For example, given:
      #
      #   Person = Structure.new do
      #     attribute :name, String
      #     attribute? :age, Integer
      #   end
      #
      # This compiler will generate:
      #
      #   class Person < Data
      #     sig { params(name: String, age: T.nilable(Integer)).returns(Person) }
      #     sig { params(name: String, age: T.nilable(Integer)).void }
      #     def initialize(name:, age: nil); end
      #
      #     sig { returns(String) }
      #     def name; end
      #
      #     sig { returns(T.nilable(Integer)) }
      #     def age; end
      #
      #     sig { params(data: T::Hash[T.any(String, Symbol), T.untyped]).returns(Person) }
      #     def self.parse(data = {}); end
      #   end
      class Structure < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::Data) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select do |klass|
              klass < ::Data && klass.respond_to?(:__structure_meta__)
            end
          end
        end

        sig { override.void }
        def decorate
          meta = constant.__structure_meta__
          return unless meta

          attributes = meta[:mappings]&.keys || constant.members
          types = meta.fetch(:types, {})
          required = meta.fetch(:required, attributes)

          root.create_path(constant) do |klass|
            generate_new_and_brackets(klass, attributes, types, required)
            generate_parse(klass)
            generate_load_dump(klass)
            generate_members(klass, attributes)
            generate_attr_readers(klass, attributes, types)
            generate_to_h(klass, attributes, types)
            generate_boolean_predicates(klass, types)
          end
        end

        private

        sig { params(klass: RBI::Scope, attributes: T::Array[Symbol], types: T::Hash[Symbol, T.untyped], required: T::Array[Symbol]).void }
        def generate_new_and_brackets(klass, attributes, types, required)
          params = attributes.map do |attr|
            type = map_type_to_sorbet(types[attr])
            is_required = required.include?(attr)
            if is_required
              create_kw_param(attr.to_s, type: type)
            else
              create_kw_opt_param(attr.to_s, type: type, default: "nil")
            end
          end

          klass.create_method("initialize", parameters: params, return_type: "void")
          klass.create_method("new", parameters: params, return_type: constant.name.to_s, class_method: true)
          klass.create_method("[]", parameters: params, return_type: constant.name.to_s, class_method: true)
        end

        sig { params(klass: RBI::Scope).void }
        def generate_parse(klass)
          klass.create_method(
            "parse",
            parameters: [
              create_opt_param("data", type: "T::Hash[T.any(String, Symbol), T.untyped]", default: "{}"),
              create_opt_param("overrides", type: "T.nilable(T::Hash[Symbol, T.untyped])", default: "nil"),
            ],
            return_type: constant.name.to_s,
            class_method: true,
          )
        end

        sig { params(klass: RBI::Scope).void }
        def generate_load_dump(klass)
          klass.create_method(
            "load",
            parameters: [create_param("data", type: "T.nilable(T::Hash[T.any(String, Symbol), T.untyped])")],
            return_type: "T.nilable(#{constant.name})",
            class_method: true,
          )
          klass.create_method(
            "dump",
            parameters: [create_param("value", type: "T.nilable(#{constant.name})")],
            return_type: "T.nilable(T::Hash[Symbol, T.untyped])",
            class_method: true,
          )
        end

        sig { params(klass: RBI::Scope, attributes: T::Array[Symbol]).void }
        def generate_members(klass, attributes)
          members_type = "[#{attributes.map { |a| ":#{a}" }.join(", ")}]"
          klass.create_method("members", return_type: members_type, class_method: true)
          klass.create_method("members", return_type: members_type)
        end

        sig { params(klass: RBI::Scope, attributes: T::Array[Symbol], types: T::Hash[Symbol, T.untyped]).void }
        def generate_attr_readers(klass, attributes, types)
          attributes.each do |attr|
            type = map_type_to_sorbet(types[attr])
            klass.create_method(attr.to_s, return_type: type)
          end
        end

        sig { params(klass: RBI::Scope, attributes: T::Array[Symbol], types: T::Hash[Symbol, T.untyped]).void }
        def generate_to_h(klass, attributes, types)
          hash_pairs = attributes.map do |attr|
            type = map_type_to_sorbet(types[attr])
            "#{attr}: #{type}"
          end.join(", ")

          klass.create_method("to_h", return_type: "{ #{hash_pairs} }")
        end

        sig { params(klass: RBI::Scope, types: T::Hash[Symbol, T.untyped]).void }
        def generate_boolean_predicates(klass, types)
          types.each do |attr, type|
            next unless type == :boolean
            next if attr.to_s.end_with?("?")

            klass.create_method("#{attr}?", return_type: "T::Boolean")
          end
        end

        sig { params(type: T.untyped).returns(String) }
        def map_type_to_sorbet(type)
          case type
          when Class
            if type == Array
              "T::Array[T.untyped]"
            elsif type == Hash
              "T::Hash[T.untyped, T.untyped]"
            else
              "T.nilable(#{type.name || "T.untyped"})"
            end
          when :boolean
            "T.nilable(T::Boolean)"
          when :self
            "T.nilable(#{constant.name})"
          when Array
            if type.size == 1
              element_type = map_type_to_sorbet_element(type.first)
              "T.nilable(T::Array[#{element_type}])"
            else
              "T.nilable(T.untyped)"
            end
          when Proc
            "T.nilable(T.untyped)"
          else
            "T.nilable(T.untyped)"
          end
        end

        sig { params(type: T.untyped).returns(String) }
        def map_type_to_sorbet_element(type)
          case type
          when Class
            type.name || "T.untyped"
          when :boolean
            "T::Boolean"
          when :self
            constant.name.to_s
          else
            "T.untyped"
          end
        end
      end
    end
  end
end
