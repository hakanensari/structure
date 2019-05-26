# frozen_string_literal: true

module Structure
  module ClassMethods
    attr_reader :attribute_names

    def self.extended(base)
      base.instance_variable_set :@attribute_names, []
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
          @__mutex__.synchronize {
            return @#{name} if defined?(@#{name})

            @#{name} = __#{name}__
            @#{name}.freeze unless @#{name}.is_a?(Structure)

            @#{name}
          }
        end
      CODE

      define_method "__#{name}__", block
      private "__#{name}__"

      @attribute_names << name

      name.to_sym
    end

    def __overwrite_initialize__
      class_eval do
        unless method_defined?(:__custom_initialize__)
          define_method :__custom_initialize__ do |*args|
            @__mutex__ = ::Thread::Mutex.new
            __original_initialize__(*args)
          end
        end

        return if instance_method(:initialize) ==
                  instance_method(:__custom_initialize__)

        alias_method :__original_initialize__, :initialize
        alias_method :initialize, :__custom_initialize__
      end
    end

    private

    def method_added(name)
      return if name != :initialize

      __overwrite_initialize__
    end

    def inherited(subclass)
      subclass.instance_variable_set :@attribute_names, @attribute_names.dup
    end
  end
end
