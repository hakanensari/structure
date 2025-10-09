#!/usr/bin/env ruby
# frozen_string_literal: true

# Performance comparison between Structure and dry-struct
# Usage: ruby perf_comparison.rb
#
# Key findings:
#
# Speed:
# - Structure uses Data.define (Ruby 3.2+) with values stored in C structs
# - dry-struct uses plain Ruby objects with type validation
#
# Memory:
# - Structure: Data.define stores values directly in C array (no Ruby @attributes hash)
# - dry-struct: Stores input hash as @attributes instance variable (persists for object lifetime)
#
# Trade-off: Structure trades temporary allocations (fast GC) for speed and lower retained memory

require "benchmark"
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "dry-struct"
  gem "dry-types"
end

# Load Structure from current gem
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "structure"

# Test data with more coercions and nested structures
TEST_DATA = {
  "attr1" => "foo",
  "attr2" => "123",         # Integer coercion
  "attr3" => "bar",
  "attr4" => "true",        # Boolean coercion
  "attr5" => ["a", "b", "c"],
  "attr6" => { "x" => "y" },
  "attr8" => "optional",
  "attr9" => "3.14",        # Float coercion
  "attr10" => "42",         # Integer coercion
  "attr11" => "1",          # Boolean coercion
  "items" => [ # Array of nested structures
    { "name" => "Item 1", "price" => "10.99" },
    { "name" => "Item 2", "price" => "20.50" },
    { "name" => "Item 3", "price" => "15.25" },
  ],
}.freeze

# Define dry-struct models
module DryStructModels
  require "dry-struct"

  module Types
    include Dry.Types()
  end

  class Item < Dry::Struct
    transform_keys(&:to_sym)

    attribute :name, Types::String
    attribute :price, Types::Coercible::Float
  end

  class Model < Dry::Struct
    transform_keys(&:to_sym)

    attribute :attr1, Types::String
    attribute :attr2, Types::Coercible::Integer
    attribute :attr3, Types::String
    attribute :attr4, Types::Params::Bool
    attribute :attr5, Types::Array
    attribute :attr6, Types::Hash
    attribute :attr7, Types::String.default("default")
    attribute? :attr8, Types::String
    attribute :attr9, Types::Coercible::Float
    attribute :attr10, Types::Coercible::Integer
    attribute :attr11, Types::Params::Bool
    attribute :items, Types::Array.of(Item)
  end
end

# Define Structure models
module StructureModels
  Item = Structure.new do
    attribute(:name, String)
    attribute(:price, Float)
  end

  Model = Structure.new do
    attribute(:attr1, String)
    attribute(:attr2, Integer)
    attribute(:attr3, String)
    attribute(:attr4, :boolean)
    attribute(:attr5)
    attribute(:attr6)
    attribute(:attr7, String, default: "default")
    attribute?(:attr8, String)
    attribute(:attr9, Float)
    attribute(:attr10, Integer)
    attribute(:attr11, :boolean)
    attribute(:items, ["Item"])
  end
end

iterations = 100_000

dry_time = nil
structure_time = nil

Benchmark.bm(15) do |x|
  dry_time = x.report("dry-struct") do
    iterations.times do
      DryStructModels::Model.new(TEST_DATA)
    end
  end

  structure_time = x.report("structure") do
    iterations.times do
      StructureModels::Model.parse(TEST_DATA)
    end
  end
end

puts
time_diff = ((structure_time.real - dry_time.real) / dry_time.real * 100)
puts "structure is #{format("%.1f", time_diff.abs)}% #{time_diff > 0 ? "slower" : "faster"}"

GC.start
before_heap = GC.stat[:heap_allocated_pages]
_dry_instances = Array.new(iterations) { DryStructModels::Model.new(TEST_DATA) }
GC.start
after_heap = GC.stat[:heap_allocated_pages]
dry_pages = after_heap - before_heap

GC.start
before_heap = GC.stat[:heap_allocated_pages]
_structure_instances = Array.new(iterations) { StructureModels::Model.parse(TEST_DATA) }
GC.start
after_heap = GC.stat[:heap_allocated_pages]
structure_pages = after_heap - before_heap

pages_diff = dry_pages - structure_pages
comparison = pages_diff.positive? ? "#{pages_diff} pages less" : "#{pages_diff.abs} pages more"
puts "structure uses #{structure_pages} pages vs #{dry_pages} pages (#{comparison})"
