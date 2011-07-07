require 'yaml'

class Structure

  # An enumerable static structure, sourced from a yaml file.
  module Static
    def self.included(base)
      base.key(:id, Integer)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Enumerable

      attr_accessor :data_path

      def all
        @all ||= data.map do |record|
          record["id"] ||= increment_id
          new(record)
        end
      end

      def each(&block)
        all.each { |record| block.call(record) }
      end

      def find(id)
        detect { |record| record.id == id }
      end

      def set_data_path(data_path)
        @data_path = data_path
      end

      private

      def data
        YAML.load_file(data_path)
      end

      # Overwrite this method with an opiniated location to dry if necessary.
      def data_path
        @data_path
      end

      def increment_id
        @increment_id = @increment_id.to_i + 1
      end
    end
  end
end
