# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name        = 'structure'
  s.version     = Structure::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hakan Ensari']
  s.email       = ['code@papercavalier.com']
  s.homepage    = 'http://github.com/hakanensari/structure'
  s.summary     = 'A typed, nestable key/value container'
  s.description = 'A typed, nestable key/value container'

  s.rubyforge_project = 'structure'

  s.add_dependency 'certainty',     '~> 0.2.0'
  s.add_dependency 'activesupport', '~> 3.0'
  s.add_dependency 'i18n',          '~> 0.6.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
