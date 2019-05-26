# frozen_string_literal: true

module Structure
  module ClassMethods
    # Creates a double that mocks a value object built with Structure during a
    # test
    #
    # The double has an alternative constructor that takes a hash to set values.
    # Otherwise, it shares the public API of the mocked value object.
    def double
      klass = Class.new(self)

      (private_instance_methods(false) + protected_instance_methods(false) -
        [:initialize]).each do |name|
        klass.send :undef_method, name
      end

      klass.module_eval do
        def initialize(values = {})
          values.each do |key, value|
            instance_variable_set :"@#{key}", value
          end
        end

        attribute_names.each do |name|
          module_eval <<-CODE, __FILE__, __LINE__ + 1
            private def __get_#{name}
              @#{name}
            end
          CODE
        end

        module_eval(&Proc.new) if block_given?
      end

      class << klass
        undef_method :double
      end

      klass
    end
  end
end
