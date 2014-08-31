module Structure
  def self.included(base)
    base.extend(ClassMethods).instance_variable_set(:@attribute_names, [])
  end

  def attributes
    attribute_names.reduce({}) { |ret, key|
      val = send(key)

      ret.update(key =>
        if val.respond_to?(:attributes)
          val.attributes
        elsif val.is_a?(Array)
          val.map { |el| el.respond_to?(:attributes) ? el.attributes : el }
        else
          val
        end
      )
    }
  end

  def attribute_names
    self.class.attribute_names
  end

  def ==(other)
    return false unless other.respond_to?(:attributes)
    attributes == other.attributes
  end

  def inspect
    class_name = self.class.name || self.class.to_s.gsub(/[^\w:]/, '')

    "#<#{class_name} #{
      attribute_names
        .map { |key|
          val = send(key)
          if val.is_a?(Array)
            "#{key}=[#{val.take(3).map(&:inspect).join(', ')}#{val.size > 3 ? '...' : ''}]"
          else
            "#{key}=#{val.inspect}"
          end
        }
        .join(', ')
    }>"
  end

  alias_method :to_h, :attributes
  alias_method :eql?, :==
  alias_method :to_s, :inspect

  module ClassMethods
    attr_reader :attribute_names

    def double(&blk)
      klass = Class.new(self)

      (private_instance_methods(false) + protected_instance_methods(false) - [:initialize])
        .each do |mth|
          klass.send(:undef_method, mth)
        end

      klass.module_eval do
        def initialize(data = {})
          data.each { |key, val| instance_variable_set(:"@#{key}", val) }
        end

        attribute_names.each do |name|
          module_eval "def _#{name}; @#{name}; end"
          private "_#{name}"
        end

        module_eval(&blk) if block_given?
      end

      klass
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
    end

    private

    def attribute(name, &blk)
      name = name.to_s

      if name.chomp!('?')
        module_eval(<<-EOS, __FILE__, __LINE__)
          def #{name}?
            #{name}
          end
        EOS
      end

      module_eval(<<-EOS, __FILE__, __LINE__)
        def #{name}
          return @#{name} if defined?(@#{name})
          @#{name} = _#{name}
          @#{name}.freeze unless @#{name}.is_a?(Structure)

          @#{name}
        end
      EOS

      define_method("_#{name}", blk)
      private "_#{name}"

      @attribute_names << name

      name.to_sym
    end
  end
end
