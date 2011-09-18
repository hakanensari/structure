source :rubygems
gemspec

gem 'activesupport', '~> 3.0'
gem 'json',          :platform => [:mri_18, :jruby, :rbx]
gem 'minitest'       if RUBY_VERSION.include? '1.8'
gem 'pry'            unless ENV['CI']
gem 'rake'
