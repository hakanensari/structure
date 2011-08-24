require 'forwardable'

module Structure
  class Collection < Array #:nodoc:[all]
    class << self
      attr :type

      alias overridden_new new

      def new(type)
        unless type < Document
          raise TypeError, "#{type} isn't a Document"
        end
        class_name = "#{type}Collection"

        begin
          class_name.constantize
        rescue NameError
          Object.class_eval <<-ruby
            class #{class_name} < Structure::Collection
              @type = #{type}
            end
          ruby
          retry
        end
      end

      private

      def inherited(child)
        Kernel.send(:define_method, child.name) do |arg|
          case arg
          when child
            arg
          else
            [arg].flatten.inject(child.new) { |a, e| a << e }
          end
        end
        child.instance_eval { alias new overridden_new }
      end
    end

    attr :members

    %w{concat eql? push replace unshift}.each do |method|
      define_method method do |ary|
        super ary.map { |item| Kernel.send(type.to_s, item) }
      end
    end

    def <<(item)
      super Kernel.send(type.to_s, item)
    end

    def create(*args)
      self.<< type.new(*args)

      true
    end

    private

    def type
      self.class.type
    end
  end
end
