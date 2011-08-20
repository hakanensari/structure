source :rubygems

gemspec

gem 'activesupport', '>= 3.0'
gem 'json',          :platform => [:mri_18, :jruby, :rbx]
gem 'rake'

platforms :mri_19 do
  gem 'ruby-debug19', :require => 'ruby-debug' unless ENV['CI']
end
