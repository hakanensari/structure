# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name          = 'structure'
  s.version       = '1.0.3'
  s.licenses      = ['MIT']
  s.summary       = 'Parse data into value objects'
  s.authors       = ['Hakan Ensari']
  s.email         = 'me@hakanensari.com'
  s.license       = 'MIT'
  s.files         = Dir.glob('lib/**/*')
  s.require_paths = ['lib']

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop'
end
