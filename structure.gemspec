# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name        = "structure"
  s.version     = Sucker::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paper Cavalier"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://rubygems.com/gems/structure"
  s.summary     = "A better Struct"
  s.description = <<-END_OF_DESCRIPTION.strip
    Structure is a better Struct and does wonders when modeling ephemeral data
    fed in from an API. It typecasts values, works with ORM-esque association
    idioms, dumps good-looking JSON, and loads the same JSON seamlessly back
    into Ruby.
    END_OF_DESCRIPTION

  s.rubyforge_project = "structure"

  {
    'rspec'         => '~> 2.6.0',
    'ruby-debug19'  => '~> 0.11.6'
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
