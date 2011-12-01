require 'minitest/autorun'

begin
  require 'pry'
rescue LoadError
end

require 'structure'

InheritedStructure = Class.new(Structure)

# Most tests below are borrowed from RubySpec.
class TestStructure < MiniTest::Unit::TestCase
  def setup
    @person = Structure.new(:name => 'John')
  end

  def test_delete_field
    @person.delete_field(:name)
    assert_nil @person.send(:table)[:name]
    refute_respond_to(@person, :name)
    refute_respond_to(@person, :name=)
  end

  def test_element_reference
    assert_raises(NoMethodError) { @person[1] }
  end

  def test_element_set
    assert_raises(NoMethodError) { @person[1] = 2 }
  end

  def test_equal_value
    refute @person == 'foo'
    assert @person == @person
    assert @person == Structure.new(:name => 'John')
    assert @person == InheritedStructure.new(:name => 'John')
    refute @person == Structure.new(:name => 'Johnny')
    refute @person == Structure.new(:name => 'John', :age => 20)
  end

  def test_frozen
    @person.freeze

    assert_equal 'John', @person.name
    assert_raises(TypeError) { @person.age = 42 }
    assert_raises(TypeError) { @person.state = :new }

    c = @person.clone
    assert_equal 'John', c.name
    assert_raises(TypeError) { c.age = 42 }
    assert_raises(TypeError) { c.state = :new }

    d = @person.dup
    assert_equal 'John', d.name
    d.age = 42
    assert_equal 42, d.age
  end

  def test_initialize_copy
    d = @person.dup
    d.name = 'Jane'
    assert_equal 'Jane', d.name
    assert_equal 'John', @person.name

    @person.friends = ['Joe']
    d = @person.dup
    d.friends = ['Jim']
    assert_equal ['Jim'], d.friends
    assert_equal ['Joe'], @person.friends
  end

  def test_json
    friend = Structure.new(:name => 'Jane')
    @person.friend = friend
    json = '{"json_class":"Structure","name":"John","friend":{"name":"Jane"}}'
    assert_equal json, @person.to_json
    assert_equal @person, JSON.parse(json)
    assert_equal friend, JSON.parse(json).friend

    refute_respond_to @person, :as_json
    require 'active_support/ordered_hash'
    require 'active_support/json'
    load 'structure.rb'
    assert @person.as_json(:only => :name).has_key?(:name)
    refute @person.as_json(:except => :name).has_key?(:name)
  end

  def test_marshaling
    assert_equal({ :name => 'John' }, @person.marshal_dump)
    @person.marshal_load(:age => 20, :name => 'Jane')
    assert_equal 20, @person.age
    assert_equal 'Jane', @person.name
  end

  def test_method_missing
    @person.test = 'test'
    assert_respond_to @person, :test
    assert_respond_to @person, :test=
    assert_equal 'test', @person.test
    assert_equal 'test', @person.send(:table)[:test]
    @person.test = 'changed'
    assert_equal 'changed', @person.test


    @person.send(:table)[:age] = 20
    assert_equal 20, @person.age

    assert_raises(NoMethodError) { @person.gender }
    assert_raises(NoMethodError) { @person.gender(1) }

    @person.freeze
    assert_raises(TypeError) { @person.gender = 'male' }
  end

  def test_new
    person = Structure.new(:name => 'John', :age => 70)
    assert_equal 'John', person.name
    assert_equal 70, person.age
    assert_equal({}, Structure.new.send(:table))
  end

  def test_new_field
    @person.send(:table)[:age] = 20
    @person.send(:new_field, :age)

    assert_equal 20, @person.age

    @person.age = 30
    assert_equal 30, @person.age

    @person.instance_eval { def gender; 'male'; end }
    @person.send(:new_field, :gender)
    assert_equal 'male', @person.gender
    refute_respond_to @person, :gender=
  end

  def test_recursive_marshaling
    hsh = {
      :name => 'John',
      :friend => { :name => 'Jane' },
      :friends => [{ :name => 'Jane' }]
    }
    friend = Structure.new(:name => 'Jane')
    @person.friend = friend
    @person.friends = [friend]
    assert_equal hsh, @person.marshal_dump

    person = Structure.new
    person.marshal_load(hsh)
    assert_equal friend, person.friend
    assert_equal friend, person.friends.first
  end

  def test_table
    assert_equal({ :name => 'John' }, @person.send(:table))
  end
end
