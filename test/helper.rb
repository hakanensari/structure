$:.push File.expand_path('../../lib', __FILE__)

require 'bundler/setup'

begin
  require 'ruby-debug'
rescue LoadError
end

require 'structure'
require 'test/unit'

Document = Structure::Document
