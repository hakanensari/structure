class User
  sig { params(id: T.nilable(String), name: T.nilable(String), bio: T.nilable(String)).void }
  def initialize(id:, name: nil, bio: nil); end

  sig { params(id: T.nilable(String), name: T.nilable(String), bio: T.nilable(String)).returns(User) }
  def self.new(id:, name: nil, bio: nil); end

  sig { params(id: T.nilable(String), name: T.nilable(String), bio: T.nilable(String)).returns(User) }
  def self.[](id:, name: nil, bio: nil); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(User) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(User)) }
  def self.load(data); end

  sig { params(value: T.nilable(User)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:id, :name, :bio]) }
  def self.members; end

  sig { returns([:id, :name, :bio]) }
  def members; end

  sig { returns(T.nilable(String)) }
  def id; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(String)) }
  def bio; end

  sig { returns({ id: T.nilable(String), name: T.nilable(String), bio: T.nilable(String) }) }
  def to_h; end
end
