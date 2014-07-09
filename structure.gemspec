Gem::Specification.new do |gem|
  gem.name    = 'structure'
  gem.version = '1.0.0'
  gem.authors = ['Hakan Ensari']
  gem.summary = 'Parses data into value objects'
  gem.files   = Dir.glob('lib/**/*') + %w(LICENSE README.md)

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.required_ruby_version = '>= 2.1'
end
