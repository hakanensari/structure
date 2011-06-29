require 'benchmark'
require 'ostruct'
require_relative 'lib/structure'

class Person1 < Structure
  key :name
end

class Person2 < Struct.new(:name)
end

class Person3
 attr_accessor :name
end

n = 100000
Benchmark.bm do |x|
  x.report('Structure')  { n.times { Person1.new(:name => 'John') } }
  x.report('Structure')  { n.times { Person1.new.name = 'John' } }
  x.report('OpenStruct') { n.times { OpenStruct.new(:name => 'John') } }
  x.report('Struct')     { n.times { Person2.new('John') } }
  x.report('Class')      { n.times { Person3.new.name = 'John' } }
  x.report('Hash')       { n.times { { name: 'John' } } }
end
