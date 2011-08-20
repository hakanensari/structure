class Structure
  module Collection
    # Returns a subclass of +Array+ that represents a collection of
    # instances of specified type.
    def self.new(type)
      unless type.is_a? Class
        raise TypeError, "#{type} isn't a Class"
      end

      class_name = "#{type}Collection"

      begin
        return Object.const_get(class_name)
      rescue NameError
      end

      klass = Object.const_set class_name, (Class.new(Array) do
        class << self
          attr :type
        end

        @type = type

        def <<(arg)
          case arg
          when type
            super
          when Hash
            super type.new(arg)
          else
            raise TypeError, "#{arg} isn't a #{type}"
          end
        end

        def create(*args)
          push type.new(*args)
        end

        private

        def type
          self.class.type
        end
      end)

      (class << Type; self; end).send(:define_method, class_name) do |arg|
        case arg
        when klass
          arg
        when Array
          arg.inject(klass.new) { |a, e| a << e }
        else
          klass.new << arg
        end
      end

      klass
    end
  end
end
