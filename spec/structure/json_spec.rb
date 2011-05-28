require 'spec_helper'

describe Structure do
  context "when `structure/json' is required" do
    let(:person) { Person.new(:name => 'Joe', :age => 28, :website => 'http://example.com') }
    let(:json) { '{"json_class":"Person","name":"Joe","age":28,"website":"http://example.com","friends":[]}' }

    before do
      require 'structure/json'
    end

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
end
