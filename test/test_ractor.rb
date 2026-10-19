# frozen_string_literal: true

require_relative "helper"
require "structure"
require "date"
require "timeout"

return unless defined?(Ractor)

class TestRactor < Minitest::Test
  DEADLINE = 30
  RACTORS = 8
  DATES = Ractor.make_shareable(["2020-01-02", "1999-12-31", "2011-06-15", "2026-10-10"])

  Upcase = Ractor.make_shareable(->(value) { value.to_s.upcase })

  module RequireWord
    class << self
      def call(shout)
        raise ArgumentError, "word is blank" if shout.word.empty?
      end
    end
  end

  LastMatch = Ractor.make_shareable(lambda do |string|
    string =~ /\d+/ if string
    Regexp.last_match(0)
  end)

  Empty = Structure.new

  Tag = Structure.new do
    attribute(:name, String, null: false)
  end

  Node = Structure.new do
    attribute(:id, Integer)
    attribute?(:raw)
    attribute?(:ratio, Float)
    attribute?(:active, :boolean)
    attribute?(:born_on, Date, from: +"bornOn")
    attribute?(:scores, [Float])
    attribute?(:tag, Tag)
    attribute?(:tags, [Tag])
    attribute?(:parent, :self)
    attribute?(:children, [:self])
    attribute?(:kind, String, default: "leaf")
    attribute?(:note, String)

    def root?
      parent.nil?
    end

    def child_of?(node)
      parent == node
    end

    class << self
      def root(id)
        parse("id" => id)
      end
    end
  end

  Named = Structure.new do
    attribute(:tag, "Tag")
    attribute?(:tags, ["Tag"])
  end

  UnfrozenNamed = Structure.new do
    attribute(:tag, +"Tag")
    attribute?(:tags, [+"Tag"])
  end

  Swappable = Structure.new do
    attribute(:tag, "Swapped")
  end

  Dated = Structure.new do
    attribute(:on, Date)
    attribute(:days, [Date])
  end

  DatedByName = Structure.new do
    attribute(:on, "Date")
    attribute(:days, ["Date"])
  end

  Shout = Structure.new do
    attribute(:word, Upcase)
    attribute?(:echo, &Upcase)
    after_parse(RequireWord)
  end

  WithBlock = Structure.new do
    attribute(:name) { |value| value.to_s.upcase }
  end

  WithLambda = Structure.new do
    attribute(:name, ->(value) { value.to_s.upcase })
  end

  WithLambdas = Structure.new do
    attribute(:names, [->(value) { value.to_s.upcase }])
  end

  WithHook = Structure.new do
    attribute(:name, String)
    after_parse { |instance| raise ArgumentError, "name is blank" if instance.name.empty? }
  end

  WithDefault = Structure.new do
    attribute?(:names, [String], default: ["none"])
  end

  INPUT = Ractor.make_shareable({
    "id" => "1",
    "raw" => { "any" => "thing" },
    "ratio" => "1.5",
    "active" => "true",
    "bornOn" => "2020-01-02",
    "scores" => ["1.5", 2],
    "tag" => { "name" => "a" },
    "tags" => [{ "name" => "b" }, { "name" => "c" }],
    "parent" => { "id" => 2 },
    "children" => [{ "id" => 3, "children" => [{ "id" => 4 }] }],
  })

  def setup
    @experimental = Warning[:experimental]
    @report_on_exception = Thread.report_on_exception
    Warning[:experimental] = false
    Thread.report_on_exception = false
  end

  def teardown
    Warning[:experimental] = @experimental
    Thread.report_on_exception = @report_on_exception
  end

  def test_parses_every_kind_of_attribute
    assert_equal(Node.parse(INPUT), in_ractor { Node.parse(INPUT) })
  end

  def test_parses_a_structure_without_attributes
    assert_equal(Empty.new, in_ractor { Empty.parse({}) })
  end

  def test_builds_with_new
    assert_equal(Node.new(id: 1, kind: "leaf"), in_ractor { Node.new(id: 1, kind: "leaf") })
  end

  def test_dumps_with_to_h
    assert_equal(Node.parse(INPUT).to_h, in_ractor { Node.parse(INPUT).to_h })
  end

  def test_compares_instances
    assert(in_ractor { Tag.parse("name" => "a") == Tag.new(name: "a") })
    refute(in_ractor { Tag.parse("name" => "a") == Tag.new(name: "b") })
  end

  def test_parses_classes_given_by_name
    expected = Named.new(tag: Tag.new(name: "a"), tags: [Tag.new(name: "b")])

    assert_equal(expected, in_ractor { Named.parse("tag" => { "name" => "a" }, "tags" => [{ "name" => "b" }]) })
  end

  def test_parses_classes_given_by_unfrozen_names
    expected = UnfrozenNamed.new(tag: Tag.new(name: "a"), tags: [Tag.new(name: "b")])

    assert_equal(
      expected,
      in_ractor { UnfrozenNamed.parse("tag" => { "name" => "a" }, "tags" => [{ "name" => "b" }]) },
    )
  end

  def test_resolves_a_named_class_once_in_each_ractor
    swapped = self.class.const_set(:Swapped, Structure.new { attribute(:name, String) })
    Swappable.parse("tag" => { "name" => "a" })
    self.class.send(:remove_const, :Swapped)
    self.class.const_set(:Swapped, Structure.new { attribute(:name, String) })

    assert_instance_of(swapped, Swappable.parse("tag" => { "name" => "a" }).tag)
    assert(in_ractor { Swappable.parse("tag" => { "name" => "a" }).tag.instance_of?(Swapped) })
  ensure
    self.class.send(:remove_const, :Swapped)
  end

  def test_parses_dates_in_many_ractors_at_once
    wrong = in_ractors do |offset|
      5_000.times.count do |i|
        date = DATES[(i + offset) % DATES.size]
        dated = Dated.parse("on" => date, "days" => [date])
        dated.on.iso8601 != date || dated.days.first.iso8601 != date
      end
    end

    assert_equal([0] * RACTORS, wrong)
  end

  def test_parses_dates_given_by_name_in_many_ractors_at_once
    wrong = in_ractors do |offset|
      5_000.times.count do |i|
        date = DATES[(i + offset) % DATES.size]
        dated = DatedByName.parse("on" => date, "days" => [date])
        dated.on.iso8601 != date || dated.days.first.iso8601 != date
      end
    end

    assert_equal([0] * RACTORS, wrong)
  end

  def test_parses_classes_given_by_name_in_many_ractors_at_once
    wrong = in_ractors do |offset|
      2_000.times.count do |i|
        name = (i + offset).to_s
        named = Named.parse("tag" => { "name" => name }, "tags" => [{ "name" => name }])
        named.tag.name != name || named.tags.first.name != name
      end
    end

    assert_equal([0] * RACTORS, wrong)
  end

  def test_ruby_still_shares_the_last_match_between_ractors
    LastMatch.call("111")

    assert_equal(
      "111",
      in_ractor { LastMatch.call(nil) },
      "Ruby no longer shares $~ between Ractors (Bug #22216). See the TODOs in Structure::Builder. The README's " \
        "warning about lambdas and Structure::Types.parse_as can go",
    )
  end

  def test_leaves_the_types_and_keys_it_is_given_unfrozen
    name = +"Tag"
    type = [name]
    key = +"Tags"
    Structure.new { attribute(:tags, type, from: key) }

    refute_predicate(name, :frozen?)
    refute_predicate(type, :frozen?)
    refute_predicate(key, :frozen?)
  end

  def test_loads_and_dumps
    assert_equal(Node.load(INPUT), in_ractor { Node.load(INPUT) })
    assert_equal(Node.dump(Node.parse(INPUT)), in_ractor { Node.dump(Node.parse(INPUT)) })
  end

  def test_answers_boolean_predicates
    assert(in_ractor { Node.parse(INPUT).active? })
  end

  def test_calls_custom_methods
    assert(in_ractor { Node.root(1).root? })
    assert(in_ractor { Node.parse(INPUT).child_of?(Node.root(2)) })
  end

  def test_takes_an_instance_from_the_main_ractor
    node = Node.parse(INPUT)

    assert(in_ractor(node) { |copy| copy == Node.parse(INPUT) })
  end

  def test_calls_shareable_callables
    assert_equal(Shout.new(word: "HEY", echo: "HO"), in_ractor { Shout.parse("word" => "hey", "echo" => "ho") })
  end

  def test_raises_from_an_after_parse_callable
    error = assert_raises(ArgumentError) { in_ractor { Shout.parse("word" => "") } }

    assert_equal("word is blank", error.message)
  end

  def test_parses_only_in_the_main_ractor_with_a_block
    assert_equal("A", WithBlock.parse("name" => "a").name)
    assert_main_ractor_only(WithBlock) { in_ractor { WithBlock.parse("name" => "a") } }
  end

  def test_parses_only_in_the_main_ractor_with_an_unshareable_lambda
    assert_equal("A", WithLambda.parse("name" => "a").name)
    assert_main_ractor_only(WithLambda) { in_ractor { WithLambda.parse("name" => "a") } }
  end

  def test_parses_only_in_the_main_ractor_with_an_array_of_an_unshareable_lambda
    assert_equal(["A"], WithLambdas.parse("names" => ["a"]).names)
    assert_main_ractor_only(WithLambdas) { in_ractor { WithLambdas.parse("names" => ["a"]) } }
  end

  def test_parses_only_in_the_main_ractor_with_an_after_parse_block
    assert_equal("a", WithHook.parse("name" => "a").name)
    assert_main_ractor_only(WithHook) { in_ractor { WithHook.parse("name" => "a") } }
  end

  def test_parses_only_in_the_main_ractor_with_an_unshareable_default
    assert_equal(["none"], WithDefault.parse({}).names)
    assert_main_ractor_only(WithDefault) { in_ractor { WithDefault.parse({}) } }
  end

  def test_loads_only_in_the_main_ractor_with_a_block
    assert_main_ractor_only(WithBlock) { in_ractor { WithBlock.load("name" => "a") } }
  end

  def test_builds_and_dumps_what_only_the_main_ractor_parses
    assert_equal({ name: "a" }, in_ractor { WithBlock.new(name: "a").to_h })
  end

  private

  def in_ractor(*args, &block)
    take([Ractor.new(*args, &block)]).first
  end

  def in_ractors(&block)
    take(Array.new(RACTORS) { |index| Ractor.new(index, &block) })
  end

  def take(ractors)
    Timeout.timeout(DEADLINE) { ractors.map { |ractor| ractor.respond_to?(:value) ? ractor.value : ractor.take } }
  rescue Ractor::RemoteError => e
    raise e.cause, cause: e.cause.cause
  end

  def assert_main_ractor_only(klass, &block)
    error = assert_raises(Ractor::IsolationError, &block)

    assert_equal(
      "#{klass} parses only in the main Ractor: a type, block, default or after_parse callback is not shareable",
      error.message,
    )
  end
end
