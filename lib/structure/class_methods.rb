# frozen_string_literal: true

module Structure
  module ClassMethods
    # Returns an array of attribute names as strings
    attr_reader :attribute_names

    def self.extended(base)
      base.instance_variable_set :@attribute_names, []
      base.send :__overwrite_initialize
    end

    def attribute(name, &block)
      name = name.to_s

      if name.end_with?('?')
        name = name.chop
        module_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}?
            #{name}
          end
        CODE
      end

      module_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          __exclusive {
            break if @__table.key?("#{name}")

            @__table["#{name}"] = __get_#{name}
            @__table["#{name}"].freeze
          }

          @__table["#{name}"]
        end
      CODE

      private define_method "__get_#{name}", block

      @attribute_names << name

      name.to_sym
    end

    private

    def __overwrite_initialize
      class_eval do
        unless method_defined?(:__custom_initialize)
          define_method :__custom_initialize do |*arguments, &block|
            @__mutex = ::Thread::Mutex.new
            @__table = {}
            __original_initialize(*arguments, &block)
            freeze
          end
        end

        return if instance_method(:initialize) ==
                  instance_method(:__custom_initialize)

        alias_method :__original_initialize, :initialize
        alias_method :initialize, :__custom_initialize
        private :__custom_initialize, :__original_initialize
      end
    end

    def method_added(name)
      __overwrite_initialize if name == :initialize
    end

    def inherited(subclass)
      subclass.instance_variable_set :@attribute_names, @attribute_names.dup
    end
  end
end
