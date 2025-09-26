# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "yard"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/test_*.rb"
end
RuboCop::RakeTask.new
YARD::Rake::YardocTask.new

desc "Run Steep type checking"
task :steep do
  sh "bundle exec steep check"
end

task default: [:rubocop, :test, :steep]
