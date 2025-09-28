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

# Simple test data for fair comparison
SIMPLE_DATA = {
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
    attribute? :name, Types::String
    attribute? :age, Types::String
    attribute? :email, Types::String
    attribute? :active, Types::String
  end
end

# Define Structure models
module StructureModels
  User = Structure.new do
    attribute(:name, String)
    attribute(:age, String)
    attribute(:email, String)
    attribute(:active, String)
  end
end

# Test that both work
puts "Testing basic functionality:"
dry_data = { "name" => "John", "age" => "30", "email" => "john@example.com", "active" => "true" }
structure_data = { "name" => "John", "age" => "30", "email" => "john@example.com", "active" => "true" }

dry_user = DryStructModels::User.new(dry_data)
structure_user = StructureModels::User.parse(structure_data)

puts "dry-struct user: #{dry_user.name}, #{dry_user.age}"
puts "Structure user: #{structure_user.name}, #{structure_user.age}"
puts

# Warm up
puts "Warming up..."
100.times do
  DryStructModels::User.new(dry_data)
  StructureModels::User.parse(structure_data)
end

# Performance test - multiple runs for reliability
iterations = 100_000

puts "Performance test (#{iterations} iterations, 5 runs):"
puts

dry_times = []
structure_times = []

5.times do |run|
  puts "Run #{run + 1}:"
  Benchmark.bm(15) do |x|
    dry_time = x.report("dry-struct") do
      iterations.times do
        DryStructModels::User.new(dry_data)
      end
    end
    dry_times << dry_time.real

    structure_time = x.report("Structure") do
      iterations.times do
        StructureModels::User.parse(structure_data)
      end
    end
    structure_times << structure_time.real
  end
  puts
end

puts "Summary across 5 runs:"
puts "dry-struct   - avg: #{format("%.4f", dry_times.sum / dry_times.length)}s, min: #{format("%.4f", dry_times.min)}s, max: #{format("%.4f", dry_times.max)}s"
puts "Structure    - avg: #{format("%.4f", structure_times.sum / structure_times.length)}s, min: #{format("%.4f", structure_times.min)}s, max: #{format("%.4f", structure_times.max)}s"

avg_diff = ((structure_times.sum / structure_times.length) - (dry_times.sum / dry_times.length)) / (dry_times.sum / dry_times.length) * 100
puts "Structure is #{format("%.1f", avg_diff.abs)}% #{avg_diff > 0 ? "slower" : "faster"} on average"

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
  DryStructModels::User.new(dry_data)
end

test_memory_usage("Structure") do
  StructureModels::User.parse(structure_data)
end

puts
puts "Ruby Data class features:"
puts "=" * 30

puts "Structure user class: #{structure_user.class}"
puts "Is a Data class: #{structure_user.class < Data}"
puts "Supports pattern matching: #{structure_user.respond_to?(:deconstruct_keys)}"

puts
puts "dry-struct user class: #{dry_user.class}"
puts "Is a Data class: #{dry_user.class < Data}"
puts "Supports pattern matching: #{dry_user.respond_to?(:deconstruct_keys)}"

puts
puts "Key handling comparison:"
puts "=" * 30

# Test key handling differences
api_data = { "UserName" => "Jane", "UserAge" => "25", "IsActive" => "true" }

puts "Original API data keys: #{api_data.keys}"

# Structure can handle original keys with mapping
UserWithMapping = Structure.new do
  attribute(:name, String, from: "UserName")
  attribute(:age, String, from: "UserAge")
  attribute(:active, String, from: "IsActive")
end

mapped_user = UserWithMapping.parse(api_data)
puts "Structure with key mapping: #{mapped_user.name}, #{mapped_user.age}, #{mapped_user.active}"

# dry-struct requires pre-transformed keys
snake_case_data = api_data.transform_keys { |k| k.to_s.gsub(/([A-Z])/, '_\1').downcase.gsub(/^_/, "") }
puts "Transformed keys for dry-struct: #{snake_case_data.keys}"

puts
puts "Summary:"
puts "=" * 30
puts "✓ Structure: Built on Ruby Data.define, zero dependencies"
puts "✓ dry-struct: Full dry-rb ecosystem, more features"
puts "✓ Structure: Native key mapping with 'from:' option"
puts "✓ dry-struct: Requires key transformation"
puts "✓ Structure: Simpler syntax for API parsing"
puts "✓ dry-struct: More powerful type system"
