# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name        = "structure"
  s.version     = Structure::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Hakan Ensari"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://code.papercavalier.com/structure"
  s.summary     = "A Struct-like key/value container"
  s.description = "Structure is a Struct-like key/value container."

  s.rubyforge_project = "structure"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
