# frozen_string_literal: true

# A tiny library for lazy parsing data with memoized attributes
module Structure
  class << self
    private

    def included(base)
      base.extend ClassMethods
    end
  end

  def attribute_names
    self.class.attribute_names
  end

  def to_a
    attribute_names.map { |key| [key, send(key)] }
  end

  def to_h
    Hash[to_a]
  end

  alias attributes to_h

  def inspect
    detail = if public_methods(false).include?(:to_s)
               to_s
             else
               to_a.map { |key, val| "#{key}=#{val.inspect}" }.join(', ')
             end

    "#<#{self.class.name || '?'} #{detail}>"
  end

  alias to_s inspect

  def ==(other)
    attributes == other.attributes
  end

  def eql?(other)
    return false if other.class != self.class

    self == other
  end

  def freeze
    attribute_names.each { |key| send(key) }
    super
  end

  private

  def with_mutex(&block)
    @mutex.owned? ? block.call : @mutex.synchronize { block.call }
  end

  # The class interface
  module ClassMethods
    attr_reader :attribute_names

    class << self
      def extended(base)
        base.instance_variable_set :@attribute_names, []
        base.send :override_initialize
      end

      private :extended
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
          with_mutex do
            break if defined?(@#{name})

            @#{name} = unmemoized_#{name}
          end

          @#{name}
        end
      CODE
      private define_method "unmemoized_#{name}", block
      @attribute_names << name

      name.to_sym
    end

    private

    def override_initialize
      class_eval do
        unless method_defined?(:overriding_initialize)
          define_method :overriding_initialize do |*arguments, &block|
            @mutex = ::Thread::Mutex.new
            original_initialize(*arguments, &block)
          end
        end

        return if instance_method(:initialize) ==
                  instance_method(:overriding_initialize)

        alias_method :original_initialize, :initialize
        alias_method :initialize, :overriding_initialize
        private :overriding_initialize, :original_initialize
      end
    end

    def method_added(name)
      override_initialize if name == :initialize
    end

    def inherited(subclass)
      subclass.instance_variable_set :@attribute_names, attribute_names.dup
    end
  end
end
