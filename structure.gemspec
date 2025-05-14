# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'structure/version'

Gem::Specification.new do |gem|
  gem.name     = 'structure'
  gem.version  = Structure::VERSION
  gem.licenses = ['MIT']
  gem.summary  = 'Lazy-parse data into attributes in a thread-safe way'
  gem.authors  = ['Hakan Ensari']
  gem.license  = 'MIT'
  gem.files    = Dir.glob('lib/**/*')

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rubocop'

  gem.required_ruby_version = ">= 3.2"
end
