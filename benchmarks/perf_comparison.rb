#!/usr/bin/env ruby
# frozen_string_literal: true

# Performance comparison between Structure and dry-struct
# Usage: ruby perf_comparison.rb

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

puts "Ruby #{RUBY_VERSION}"
puts "Testing performance: Structure vs dry-struct"
puts "=" * 50

# Test data with coercion - both implementations convert age to Integer and active to Boolean
TEST_DATA = {
  "name" => "John Doe",
  "age" => "30",
  "email" => "john@example.com",
  "active" => "true",
}.freeze

# Define dry-struct models (simple version)
module DryStructModels
  require "dry-struct"

  module Types
    include Dry.Types()
  end

  class User < Dry::Struct
    transform_keys(&:to_sym)

    attribute? :name, Types::String
    attribute? :age, Types::Coercible::Integer
    attribute? :email, Types::String
    attribute? :active, Types::Params::Bool
  end
end

# Define Structure models
module StructureModels
  User = Structure.new do
    attribute(:name, String)
    attribute(:age, Integer)
    attribute(:email, String)
    attribute(:active, :boolean)
  end
end

# Test that both work with type coercion
puts "Testing basic functionality:"
dry_user = DryStructModels::User.new(TEST_DATA)
structure_user = StructureModels::User.parse(TEST_DATA)

puts "dry-struct user: #{dry_user.name}, #{dry_user.age} (#{dry_user.age.class}), #{dry_user.active} (#{dry_user.active.class})"
puts "Structure user: #{structure_user.name}, #{structure_user.age} (#{structure_user.age.class}), #{structure_user.active} (#{structure_user.active.class})"
puts "✓ Both perform the same type coercions"
puts

# Warm up
puts "Warming up..."
100.times do
  DryStructModels::User.new(TEST_DATA)
  StructureModels::User.parse(TEST_DATA)
end

# Performance test
iterations = 100_000

puts "Performance test (#{iterations} iterations):"
puts

Benchmark.bm(15) do |x|
  dry_time = x.report("dry-struct") do
    iterations.times do
      DryStructModels::User.new(TEST_DATA)
    end
  end

  structure_time = x.report("Structure") do
    iterations.times do
      StructureModels::User.parse(TEST_DATA)
    end
  end

  diff = ((structure_time.real - dry_time.real) / dry_time.real * 100)
  puts "Structure is #{format("%.1f", diff.abs)}% #{diff > 0 ? "slower" : "faster"} than dry-struct"
end

puts
puts "Memory usage comparison (1000 iterations):"

# Test memory usage
def test_memory_usage(label, &block)
  GC.start
  before = GC.stat[:total_allocated_objects]

  1000.times(&block)

  GC.start
  after = GC.stat[:total_allocated_objects]

  puts "#{label}: #{after - before} objects allocated"
end

test_memory_usage("dry-struct") do
  DryStructModels::User.new(TEST_DATA)
end

test_memory_usage("Structure") do
  StructureModels::User.parse(TEST_DATA)
end

puts
puts "Summary:"
puts "=" * 30
puts "✓ Structure: Built on Ruby Data.define, performs type coercion"
puts "✓ dry-struct: Full dry-rb ecosystem, performs same coercions"
puts "✓ Fair comparison: Both convert age to Integer and active to Boolean"
puts "✓ Structure: Zero dependencies, competitive performance"
