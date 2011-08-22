$:.push File.expand_path('../../lib', __FILE__)

require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'

require 'active_support/testing/isolation'

Test::Unit::TestCase.send :include, ActiveSupport::Testing::Isolation

Object.const_set(:Document, Structure::Document)
