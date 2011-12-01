source :rubygems
gemspec

gem 'activesupport' # Required for testing Rails compatibility
gem 'pry' unless ENV['CI']

if RUBY_VERSION.include? '1.8'
  gem 'json'
  gem 'minitest'
end
