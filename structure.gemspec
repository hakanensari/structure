# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'structure/version'

Gem::Specification.new do |s|
  s.name          = 'structure'
  s.version       = Structure::VERSION
  s.licenses      = ['MIT']
  s.summary       = 'Parse data into value objects'
  s.authors       = ['Hakan Ensari']
  s.license       = 'MIT'
  s.files         = Dir.glob('lib/**/*')
end
