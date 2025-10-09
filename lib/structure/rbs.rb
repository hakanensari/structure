# frozen_string_literal: true

require "fileutils"
require "pathname"

module Structure
  # Generates RBS type signatures for Structure classes
  #
  # Note: Custom methods defined in Structure blocks are not included and must be manually added to RBS files. This is
  # consistent with how Ruby's RBS tooling handles Data classes.
  module RBS
    class << self
      def emit(klass)
        return unless klass < Data

        class_name = klass.name
        return unless class_name

        # @type var meta: Hash[Symbol, untyped]
        meta = klass.respond_to?(:__structure_meta__) ? klass.__structure_meta__ : {}

        attributes = meta[:mappings] ? meta[:mappings].keys : klass.members
        types = meta.fetch(:types, {}) # steep:ignore
        required = meta.fetch(:required, attributes) # steep:ignore

        emit_rbs_content(
          class_name:,
          attributes:,
          types:,
          required:,
          has_structure_modules: meta.any?,
        )
      end

      def write(klass, dir: "sig")
        rbs_content = emit(klass)
        return unless rbs_content

        # User::Address -> user/address.rbs
        path_segments = klass.name.split("::").map(&:downcase)
        filename = "#{path_segments.pop}.rbs"

        # full path
        dir_path = Pathname.new(dir)
        dir_path = dir_path.join(*path_segments) unless path_segments.empty?
        FileUtils.mkdir_p(dir_path)

        file_path = dir_path.join(filename).to_s
        File.write(file_path, rbs_content)

        file_path
      end

      private

      def emit_rbs_content(class_name:, attributes:, types:, required:, has_structure_modules:)
        # @type var lines: Array[String]
        lines = []
        lines << "class #{class_name} < Data"

        unless attributes.empty?
          # map types to rbs
          rbs_types = attributes.map do |attr|
            type = types.fetch(attr, nil)
            rbs_type = map_type_to_rbs(type, class_name)

            [attr, rbs_type != "untyped" ? "#{rbs_type}?" : rbs_type]
          end.to_h

          # Sort keyword params: required first, then optional (with ? prefix)
          # Within each group, maintain declaration order
          required_params = required.map { |attr| "#{attr}: #{rbs_types[attr]}" }
          optional_params = (attributes - required).map { |attr| "?#{attr}: #{rbs_types[attr]}" }
          keyword_params = (required_params + optional_params).join(", ")
          positional_params = attributes.map { |attr| rbs_types[attr] }.join(", ")

          needs_parse_data = types.any? do |_attr, type|
            type == :self || type == [:self]
          end

          # Generate type alias first if needed (RBS::Sorter puts types at top)
          if needs_parse_data
            lines << "  type parse_data = { " + attributes.map { |attr|
              type = types.fetch(attr, nil)
              parse_type = parse_data_type(type, class_name)
              "?#{attr}: #{parse_type}"
            }.join(", ") + " }"
          end

          lines << "  def self.new: (#{keyword_params}) -> #{class_name}"
          lines << "              | (#{positional_params}) -> #{class_name}"
          lines << ""
          lines << "  def self.[]: (#{keyword_params}) -> #{class_name}"
          lines << "             | (#{positional_params}) -> #{class_name}"
          lines << ""

          # Generate members tuple type
          members_tuple = attributes.map { |attr| ":#{attr}" }.join(", ")
          lines << "  def self.members: () -> [ #{members_tuple} ]"
          lines << ""

          # Generate parse method signatures
          if needs_parse_data
            lines << "  def self.parse: (?parse_data data) -> #{class_name}"
            lines << "                | (?Hash[String, untyped] data) -> #{class_name}"
          else
            # Remove optional parentheses to match RBS::Sorter style
            lines << "  def self.parse: (?Hash[String | Symbol, untyped], **untyped) -> #{class_name}"
          end
          lines << ""

          # Sort attr_reader lines alphabetically (RBS::Sorter does this)
          attributes.sort.each do |attr|
            lines << "  attr_reader #{attr}: #{rbs_types[attr]}"
          end

          # Add boolean predicates
          boolean_predicates = types.sort.select { |attr, type| type == :boolean && !attr.to_s.end_with?("?") }
          unless boolean_predicates.empty?
            lines << ""
            boolean_predicates.each do |attr, _type|
              lines << "  def #{attr}?: () -> bool"
            end
          end

          # Instance members method comes after attr_readers and predicates
          lines << "  def members: () -> [ #{members_tuple} ]"
          lines << ""

          hash_type = attributes.map { |attr| "#{attr}: #{rbs_types[attr]}" }.join(", ")
          lines << "  def to_h: () -> { #{hash_type} }"
        end

        lines << "end"
        lines.join("\n")
      end

      def parse_data_type(type, class_name)
        case type
        when [:self]
          "Array[#{class_name} | parse_data]"
        when Array
          if type.size == 1 && type.first == :self
            "Array[#{class_name} | parse_data]"
          elsif type.size == 1
            # Regular array type like [String], [Integer], etc.
            # Use Array[untyped] since we coerce values
            "Array[untyped]"
          else
            "untyped"
          end
        when :self
          "#{class_name} | parse_data"
        else
          "untyped"
        end
      end

      def map_type_to_rbs(type, class_name)
        case type
        when Class
          if type == Array
            "Array[untyped]"
          elsif type == Hash
            "Hash[untyped, untyped]"
          else
            type.name || "untyped"
          end

        when :boolean
          "bool"
        when :self
          class_name || "untyped"
        when Array
          if type.size == 1
            # Single element array means array of that type
            element_type = map_type_to_rbs(type.first, class_name)
            "Array[#{element_type}]"
          else
            "untyped"
          end
        else
          "untyped"
        end
      end
    end
  end
end
