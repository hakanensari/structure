# frozen_string_literal: true

require "fileutils"
require "pathname"

module Structure
  module RBS
    class << self
      def emit(klass)
        return unless klass < Data

        class_name = klass.name
        return unless class_name

        # @type var meta: Hash[Symbol, untyped]
        meta = klass.respond_to?(:__structure_meta__) ? klass.__structure_meta__ : {}

        emit_rbs_content(
          class_name: class_name,
          attributes: meta.fetch(:attributes, klass.members),
          types: meta.fetch(:types, {}), # steep:ignore
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

      def emit_rbs_content(class_name:, attributes:, types:, has_structure_modules:)
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

          keyword_params = attributes.map { |attr| "#{attr}: #{rbs_types[attr]}" }.join(", ")
          positional_params = attributes.map { |attr| rbs_types[attr] }.join(", ")

          lines << "  def self.new: (#{keyword_params}) -> instance"
          lines << "              | (#{positional_params}) -> instance"
          lines << ""

          needs_parse_data = types.any? do |_attr, type|
            type == :self || type == [:self] || (type.is_a?(Array) && type.first == :array)
          end

          if needs_parse_data
            lines << "  type parse_data = {"
            attributes.each do |attr|
              type = types.fetch(attr, nil)
              parse_type = parse_data_type(type, class_name)
              lines << "    ?#{attr}: #{parse_type},"
            end
            lines[-1] = lines[-1].chomp(",")
            lines << "  }"
            lines << ""
            lines << "  def self.parse: (?parse_data data) -> instance"
            lines << "                | (?Hash[String, untyped] data) -> instance"
          else
            # For structures without special types, just use Hash
            lines << "  def self.parse: (?(Hash[String | Symbol, untyped]), **untyped) -> instance"
          end
          lines << ""

          attributes.each do |attr|
            lines << "  attr_reader #{attr}: #{rbs_types[attr]}"
          end
          lines << ""

          types.each do |attr, type|
            if type == :boolean && !attr.to_s.end_with?("?")
              lines << "  def #{attr}?: () -> bool"
            end
          end

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
          if type.first == :array && type.last == :self
            "Array[#{class_name} | parse_data]"
          elsif type.first == :array
            # For [:array, SomeType] format, use Array[untyped] since we coerce
            "Array[untyped]"
          elsif type.size == 1 && type.first == :self
            # [:self] is handled above, this shouldn't happen
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
          type.name || "untyped"
        when :boolean
          "bool"
        when :self
          class_name || "untyped"
        when Array
          if type.size == 2 && type.first == :array
            element_type = map_type_to_rbs(type.last, class_name)
            "Array[#{element_type}]"
          elsif type.size == 1
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
