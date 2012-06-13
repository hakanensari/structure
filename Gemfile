source :rubygems
gemspec

gem 'activesupport'
gem 'minitest' if RUBY_VERSION.include? '1.8'
gem 'rake'

begin
  JSON::JSON_LOADED
rescue NameError
  gem 'json'
end
