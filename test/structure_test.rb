require 'minitest/spec'
require File.expand_path('../../lib/structure', __FILE__)

MiniTest::Unit.autorun

describe Structure do
  before do
    @hash = {
      :name     => "John",
      :children => [ { :name => "Jim" } ],
      :location => { :city => { :name => "London" } }
    }
  end

  describe ".new" do
    before do
      @person = Structure.new(@hash)
    end

    it "structures nested hashes" do
      @person.location.city.name.must_equal "London"
    end

    it "structures hashes in arrays" do
      @person.children.must_be_instance_of Array
      @person.children.first.name.must_equal "Jim"
    end
  end

  describe "#=" do
    before do
      @person = Structure.new
    end

    it "structures nested hashes" do
      @person.location = { :city => { :name => "London" } }
      @person.location.city.name.must_equal "London"
    end

    it "structures hashes in arrays" do
      @person.children = [ { :name => "Jim" } ]
      @person.children.must_be_instance_of Array
      @person.children.first.name.must_equal "Jim"
    end
  end
end
