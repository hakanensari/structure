require 'spec_helper'

shared_examples_for "a JSON interface" do
  it "dumps to JSON" do
    person.to_json.should eql json
  end

  it "loads from JSON" do
    JSON.parse(json).should == person
  end

  context "when nesting other structures" do
    before do
      person.friends = [Person.new(:name => 'Jane')]
    end

    it "loads them into their corresponding structures" do
      json = person.to_json
      JSON.parse(json).friends.first.should be_a Person
    end
  end
end

describe Structure do
  let(:person) { Person.new(:name => 'Joe') }
  let(:json) { '{"json_class":"Person","name":"Joe","age":null,"friends":[]}' }

  context "without Active Support" do
    before(:all) do
      require 'structure/json'
    end

    it_behaves_like "a JSON interface"
  end

  context "with Active Support" do
    before(:all) do
      require 'active_support/ordered_hash'
      require 'active_support/json'
      load 'structure/json.rb'
    end

    after(:all) do
      Object.send(:remove_const, :ActiveSupport)
    end

    it_behaves_like "a JSON interface"

    describe "#as_json" do
      it "returns a hash" do
        person.as_json.should be_a Hash
      end

      it "selects a subset of attributes" do
        as_json = person.as_json(:only => :name)
        as_json.should have_key :name
        as_json.should_not have_key :age
      end

      it "rejects a subset of attributes" do
        as_json = person.as_json(:except => :name)
        as_json.should_not have_key :name
        as_json.should have_key :age
      end
    end
  end
end
