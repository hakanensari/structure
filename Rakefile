# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "steep/rake_task"
require "yard"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/test_*.rb"
end
RuboCop::RakeTask.new
Steep::RakeTask.new
YARD::Rake::YardocTask.new

task default: [:rubocop, :test, :steep]
