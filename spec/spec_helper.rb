require "rubygems"
require "bundler/setup"
require "rspec"

require_relative "../lib/structure"

Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].each { |f| require f }
