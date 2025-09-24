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

        meta = klass.respond_to?(:__structure_meta__) ? klass.__structure_meta__ : {}

        emit_rbs_content(
          class_name: class_name,
          attributes: meta.fetch(:attributes, klass.members),
          types: meta.fetch(:types, {}),
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

        file_path = dir_path.join(filename)
        File.write(file_path, rbs_content)

        file_path.to_s
      end

      private

      def emit_rbs_content(class_name:, attributes:, types:, has_structure_modules:)
        lines = []
        lines << "class #{class_name} < Data"
        lines << "  extend Structure::ClassMethods" if has_structure_modules
        lines << "  include Structure::InstanceMethods"
        lines << ""

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
          elsif type == [:self]
            "Array[#{class_name || "untyped"}]"
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
