module Structure
  module ClassMethods
    def double
      klass = Class.new(self)

      (
        private_instance_methods(false) +
        protected_instance_methods(false) -
        [:initialize]
      ).each do |name|
        klass.send(:undef_method, name)
      end

      klass.module_eval do
        def initialize(data = {})
          data.each { |key, value|
            instance_variable_set(:"@#{key}", value)
          }
        end

        attribute_names.each do |name|
          module_eval "def _#{name}; @#{name}; end"
          private "_#{name}"
        end

        module_eval(&Proc.new) if block_given?
      end

      klass
    end
  end
end