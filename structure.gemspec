# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name        = "structure"
  s.version     = Structure::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paper Cavalier"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://code.papercavalier.com/structure"
  s.summary     = "A module that turns a class into a key/value container"
  s.description = <<-END_OF_DESCRIPTION.strip
    Structure is a Ruby module that turns a class into a key/value container.
    END_OF_DESCRIPTION

  s.rubyforge_project = "structure"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
