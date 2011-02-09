# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "structure"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paper Cavalier"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = ""
  s.summary     = %q{Structure is a nested OpenStruct implementation.}
  s.description = %q{A nested OpenStruct implementation}

  s.rubyforge_project = "structure"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
