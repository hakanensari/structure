class TreeNode
  sig { params(name: T.nilable(String), tags: T.nilable(T::Array[String]), children: T.nilable(T::Array[TreeNode])).void }
  def initialize(name:, tags:, children:); end

  sig { params(name: T.nilable(String), tags: T.nilable(T::Array[String]), children: T.nilable(T::Array[TreeNode])).returns(TreeNode) }
  def self.new(name:, tags:, children:); end

  sig { params(name: T.nilable(String), tags: T.nilable(T::Array[String]), children: T.nilable(T::Array[TreeNode])).returns(TreeNode) }
  def self.[](name:, tags:, children:); end

  sig { params(data: T::Hash[T.any(String, Symbol), T.untyped], overrides: T.nilable(T::Hash[Symbol, T.untyped])).returns(TreeNode) }
  def self.parse(data = {}, overrides = nil); end

  sig { params(data: T.nilable(T::Hash[T.any(String, Symbol), T.untyped])).returns(T.nilable(TreeNode)) }
  def self.load(data); end

  sig { params(value: T.nilable(TreeNode)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.dump(value); end

  sig { returns([:name, :tags, :children]) }
  def self.members; end

  sig { returns([:name, :tags, :children]) }
  def members; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(T::Array[String])) }
  def tags; end

  sig { returns(T.nilable(T::Array[TreeNode])) }
  def children; end

  sig { returns({ name: T.nilable(String), tags: T.nilable(T::Array[String]), children: T.nilable(T::Array[TreeNode]) }) }
  def to_h; end
end
