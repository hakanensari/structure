class Product
  sig { params(name: T.nilable(String), price: T.nilable(Float)).void }
  def initialize(name:, price:); end

  sig { params(name: T.nilable(String), price: T.nilable(Float)).returns(Product) }
  def self.new(name:, price:); end

  sig { params(name: T.nilable(String), price: T.nilable(Float)).returns(Product) }
  def self.[](name:, price:); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(Product) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(Product)) }
  def self.load(data); end

  sig { params(value: T.nilable(Product)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:name, :price]) }
  def self.members; end

  sig { returns([:name, :price]) }
  def members; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(Float)) }
  def price; end

  sig { returns({ name: T.nilable(String), price: T.nilable(Float) }) }
  def to_h; end
end
