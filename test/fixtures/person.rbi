class Person
  sig { params(name: T.nilable(String), age: T.nilable(Integer), active: T.nilable(T::Boolean), email: T.nilable(String)).void }
  def initialize(name:, age: nil, active:, email:); end

  sig { params(name: T.nilable(String), age: T.nilable(Integer), active: T.nilable(T::Boolean), email: T.nilable(String)).returns(Person) }
  def self.new(name:, age: nil, active:, email:); end

  sig { params(name: T.nilable(String), age: T.nilable(Integer), active: T.nilable(T::Boolean), email: T.nilable(String)).returns(Person) }
  def self.[](name:, age: nil, active:, email:); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(Person) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(Person)) }
  def self.load(data); end

  sig { params(value: T.nilable(Person)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:name, :age, :active, :email]) }
  def self.members; end

  sig { returns([:name, :age, :active, :email]) }
  def members; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(Integer)) }
  def age; end

  sig { returns(T.nilable(T::Boolean)) }
  def active; end

  sig { returns(T.nilable(String)) }
  def email; end

  sig { returns({ name: T.nilable(String), age: T.nilable(Integer), active: T.nilable(T::Boolean), email: T.nilable(String) }) }
  def to_h; end

  sig { returns(T::Boolean) }
  def active?; end
end
