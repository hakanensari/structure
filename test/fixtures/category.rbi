class Category
  sig { params(name: T.nilable(String), children: T.nilable(T::Array[Category])).void }
  def initialize(name:, children:); end

  sig { params(name: T.nilable(String), children: T.nilable(T::Array[Category])).returns(Category) }
  def self.new(name:, children:); end

  sig { params(name: T.nilable(String), children: T.nilable(T::Array[Category])).returns(Category) }
  def self.[](name:, children:); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(Category) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(Category)) }
  def self.load(data); end

  sig { params(value: T.nilable(Category)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:name, :children]) }
  def self.members; end

  sig { returns([:name, :children]) }
  def members; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(T::Array[Category])) }
  def children; end

  sig { returns({ name: T.nilable(String), children: T.nilable(T::Array[Category]) }) }
  def to_h; end
end
