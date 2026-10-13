# frozen_string_literal: true

require_relative "helper"
require "open3"
require "rbconfig"

class TestWithoutRactor < Minitest::Test
  SCRIPT = <<~RUBY
    Object.send(:remove_const, :Ractor) if defined?(Ractor)
    require "structure"

    Item = Structure.new do
      attribute(:name, String)
    end

    Order = Structure.new do
      attribute(:id, Integer)
      attribute?(:paid, :boolean)
      attribute?(:item, "Item")
      attribute?(:items, ["Item"])
      attribute?(:tags, [String], default: ["none"])
      attribute?(:note) { |value| value.to_s.upcase }

      after_parse { |order| raise ArgumentError, "id is negative" if order.id.negative? }
    end

    data = { "id" => "1", "paid" => "true", "item" => { "name" => "a" }, "items" => [{ "name" => "b" }], "note" => "c" }
    order = Order.parse(data)
    again = Order.parse(data)
    puts [order.id, order.paid?, order.item.name, order.items.map(&:name), order.tags, order.note].join(",")
    puts [order == again, Order.load(Order.dump(order)).item == order.item, Order.new(id: 2).to_h[:id]].join(",")

    item = Object.send(:remove_const, :Item)
    Item = Structure.new do
      attribute(:name, String)
    end
    puts Order.parse(data).item.instance_of?(item)
  RUBY

  def test_parses_where_ruby_has_no_ractor
    lib = $LOAD_PATH.find { |path| File.exist?(File.join(path, "structure.rb")) }
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", SCRIPT)

    assert_predicate(status, :success?, output)
    assert_equal("1,true,a,b,none,C\ntrue,true,2\ntrue\n", output)
  end
end
