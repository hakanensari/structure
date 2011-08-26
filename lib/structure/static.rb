require 'yaml'

# This module provides the class methods that render a structure
# static, where records are sourced from a YAML file.
class Structure
  module Static
    include Enumerable

    def self.extended(base)
      base.key(:_id, Integer)
    end

    # The data file path.
    attr :data_path

    # Returns all records.
    def all
      @all ||= YAML.load_file(data_path).map do |hsh|
        hsh['_id'] ||= hsh.delete('id') || hsh.delete('ID') || incr_id
        new(hsh)
      end
    end

    # Yields each record to given block.
    def each(&block)
      all.each { |item| block.call(item) }
    end

    # Finds a record by its ID.
    def find(id)
      super() { |item| item._id == id }
    end

    private

    def incr_id
      @id_cnt = @id_cnt.to_i + 1
    end
  end
end
