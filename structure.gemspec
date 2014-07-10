Gem::Specification.new do |gem|
  gem.name = 'structure'
  gem.version = '0.27.4'
  gem.authors = ['Hakan Ensari']
  gem.summary = 'Parses data into value objects'
  gem.files = %w(structure.rb structure_test.rb LICENSE README.md)
  gem.require_paths = ['.']
  gem.required_ruby_version = '>= 1.9'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
end
