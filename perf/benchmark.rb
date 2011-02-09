require 'benchmark'
require File.expand_path('../../lib/structure', __FILE__)

COUNT = 100000

User = Struct.new(:name, :age)

Benchmark.bm 20 do |x|
  x.report 'Struct' do
    COUNT.times do |index|
       User.new("User", 21)
    end
  end

  x.report 'OpenStruct' do
    COUNT.times do |index|
       OpenStruct.new(:name => "User", :age => 21)
    end
  end

  x.report 'Structure' do
    COUNT.times do |index|
       Structure.new(:name => "User", :age => 21)
    end
  end
end

