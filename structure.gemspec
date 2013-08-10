# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'structure/version'

Gem::Specification.new do |spec|
  spec.name          = 'structure'
  spec.version       = Structure::VERSION
  spec.authors       = ['Hakan Ensari']
  spec.email         = ['hakan.ensari@papercavalier.com']
  spec.description   = 'Value objects in Ruby'
  spec.summary       = 'Value objects in Ruby'
  spec.homepage      = 'http://github.com/hakanensari/structure'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
