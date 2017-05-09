module Structure
  # ClassMethods
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
          data.each do |key, value|
            value.freeze unless value.is_a?(Structure)
            instance_variable_set(:"@#{key}", value)
          end
        end

        attribute_names.each do |name|
          module_eval "def _#{name}; @#{name}; end"
          private "_#{name}"
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
