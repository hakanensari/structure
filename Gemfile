source :rubygems

gemspec

gem 'activesupport', '~> 3.0'
gem 'json', :platform => [:mri_18, :jruby, :rbx]
gem 'rake'

unless ENV['CI']
  gem 'ruby-debug',   :platforms => :mri_18
  gem 'ruby-debug19', :platforms => :mri_19
end
