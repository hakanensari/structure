class TagCollection
  sig { params(tags: T.nilable(T::Array[String]), numbers: T.nilable(T::Array[Integer]), flags: T.nilable(T::Array[T::Boolean])).void }
  def initialize(tags:, numbers:, flags:); end

  sig { params(tags: T.nilable(T::Array[String]), numbers: T.nilable(T::Array[Integer]), flags: T.nilable(T::Array[T::Boolean])).returns(TagCollection) }
  def self.new(tags:, numbers:, flags:); end

  sig { params(tags: T.nilable(T::Array[String]), numbers: T.nilable(T::Array[Integer]), flags: T.nilable(T::Array[T::Boolean])).returns(TagCollection) }
  def self.[](tags:, numbers:, flags:); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(TagCollection) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(TagCollection)) }
  def self.load(data); end

  sig { params(value: T.nilable(TagCollection)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:tags, :numbers, :flags]) }
  def self.members; end

  sig { returns([:tags, :numbers, :flags]) }
  def members; end

  sig { returns(T.nilable(T::Array[String])) }
  def tags; end

  sig { returns(T.nilable(T::Array[Integer])) }
  def numbers; end

  sig { returns(T.nilable(T::Array[T::Boolean])) }
  def flags; end

  sig { returns({ tags: T.nilable(T::Array[String]), numbers: T.nilable(T::Array[Integer]), flags: T.nilable(T::Array[T::Boolean]) }) }
  def to_h; end
end
