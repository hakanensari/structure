$:.push File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'
