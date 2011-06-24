# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name        = "structure"
  s.version     = Structure::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paper Cavalier"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://rubygems.com/gems/structure"
  s.summary     = "Struct-like key/value container in Ruby"
  s.description = <<-END_OF_DESCRIPTION.strip
    Structure is a Struct-like key/value container for modeling ephemeral data
    in Ruby.
    END_OF_DESCRIPTION

  s.rubyforge_project = "structure"

  {
    'activesupport'  => '>= 3.0',
    'rspec'          => '~> 2.6',
    'ruby-debug19'   => '~> 0.11.6'
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
