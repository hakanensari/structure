# When included in a structure, this module turns it into a static
# model, the data of which is sourced from a yaml file.
#
# This is a basic implementation and does not handle nested structures.
# See test.
class Structure
  module Static
    def self.included(base)
      base.key(:_id, Integer)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Enumerable

      # The path for the data file.
      #
      # This file should contain a YAML representation of the records.
      #
      # Overwrite this reader with an opiniated location to dry.
      attr :data_path

      # Returns all records.
      def all
        @records ||= data.map do |record|
          record['_id'] ||= record.delete('id') || increment_id
          new(record)
        end
      end

      # Yields each record to given block.
      #
      # Other enumerators will be made available by the Enumerable
      # module.
      def each(&block)
        all.each { |record| block.call(record) }
      end

      # Finds a record by its ID.
      def find(id)
        detect { |record| record._id == id }
      end

      # Sets the path for the data file.
      def set_data_path(data_path)
        @data_path = data_path
      end

      private

      def data
        YAML.load_file(@data_path)
      end


      def increment_id
        @increment_id = @increment_id.to_i + 1
      end
    end
  end
end
