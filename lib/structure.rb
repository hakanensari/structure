# frozen_string_literal: true

# Structure
module Structure
  class << self
    private

    def included(base)
      base.extend(ClassMethods)
      base.__overwrite_initialize
      base.instance_eval do
        @attribute_names = []

        def method_added(name)
          return if name != :initialize

          __overwrite_initialize
        end
      end
    end
  end

  def attributes
    attribute_names.reduce({}) do |hash, key|
      value = send(key)
      hash.update(
        key =>
          if value.respond_to?(:attributes)
            value.attributes
          elsif value.is_a?(::Array)
            value.map do |element|
              if element.respond_to?(:attributes)
                element.attributes
              else
                element
              end
            end
          else
            value
          end
      )
    end
  end

  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    return false unless other.respond_to?(:attributes)

    attributes == other.attributes
  end

  def inspect
    name = self.class.name || self.class.to_s.gsub(/[^\w:]/, '')
    values =
      attribute_names
      .map do |key|
        value = send(key)
        if value.is_a?(::Array)
          description = value.take(3).map(&:inspect).join(', ')
          description += '...' if value.size > 3
          "#{key}=[#{description}]"
        else
          "#{key}=#{value.inspect}"
        end
      end
      .join(', ')

    "#<#{name} #{values}>"
  end

  alias to_h attributes
  alias eql? ==
  alias to_s inspect

  # ClassMethods
  module ClassMethods
    attr_reader :attribute_names

    def attribute(name)
      name = name.to_s

      if name.chomp!('?')
        module_eval(<<-CODE, __FILE__, __LINE__ + 1)
          def #{name}?
            #{name}
          end
        CODE
      end

      module_eval(<<-CODE, __FILE__, __LINE__ + 1)
        def #{name}
          @__mutex.synchronize {
            return @#{name} if defined?(@#{name})

            @#{name} = __#{name}
            @#{name}.freeze unless @#{name}.is_a?(Structure)

            @#{name}
          }
        end
      CODE

      define_method("__#{name}", Proc.new)
      private "__#{name}"

      @attribute_names << name

      name.to_sym
    end

    def __overwrite_initialize
      class_eval do
        unless method_defined?(:__custom_initialize)
          define_method(:__custom_initialize) do |*args|
            @__mutex = ::Thread::Mutex.new
            __original_initialize(*args)
          end
        end

        if instance_method(:initialize) != instance_method(:__custom_initialize)
          alias_method :__original_initialize, :initialize
          alias_method :initialize, :__custom_initialize
        end
      end
    end

    private

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
    end
  end
end
