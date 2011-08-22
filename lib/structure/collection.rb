require 'forwardable'

module Structure
  class Collection #:nodoc:[all]
    extend Forwardable

    Enumerable.instance_methods.each do |method|
      def_delegator :@members, method
    end

    def_delegators :@members, :clear, :empty?, :last, :size, :to_json

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

    def initialize
      @members = []
    end

    def ==(other)
      @members == other.members
    end

    def <<(item)
      @members << Kernel.send(type.to_s, item)

      self
    end

    def create(*args)
      @members << type.new(*args)

      true
    end

    def dup
      @members = @members.dup

      super
    end

    private

    def type
      self.class.type
    end
  end
end
