$:.push File.expand_path('../../lib', __FILE__)

require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'

Object.const_set(:Document, Structure::Document)
