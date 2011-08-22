source :rubygems

gemspec

gem 'json',          :platform => [:mri_18, :jruby, :rbx]
gem 'rake'

platforms :mri_18 do
  gem 'ruby-debug', :require => 'ruby-debug' unless ENV['CI']
end

platforms :mri_19 do
  gem 'ruby-debug19', :require => 'ruby-debug' unless ENV['CI']
end
