Gem::Specification.new do |gem|
  gem.name = 'structure'
  gem.version = '0.27.1'
  gem.authors = ['Hakan Ensari']
  gem.summary = 'Parses data into value objects'
  gem.files = %w(structure.rb structure_test.rb LICENSE README.md)
  gem.require_paths = ['.']
  gem.required_ruby_version = '>= 2.1'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
end
