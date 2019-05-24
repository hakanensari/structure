# frozen_string_literal: true

module Structure
  module ClassMethods
    def double
      klass = Class.new(self)

      (
        private_instance_methods(false) +
        protected_instance_methods(false) -
        [:initialize]
      ).each do |name|
        klass.send :undef_method, name
      end

      klass.module_eval do
        def initialize(data = {})
          data.each do |key, value|
            instance_variable_set :"@#{key}", value
          end
        end

        attribute_names.each do |name|
          module_eval <<-CODE, __FILE__, __LINE__ + 1
            def __#{name}__
              @#{name}
            end
          CODE
          private "__#{name}__"
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
