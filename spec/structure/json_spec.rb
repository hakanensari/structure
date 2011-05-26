require 'spec_helper'

describe Structure do
  context "when `structure/json' is required" do
    let(:person) { Person.new(:name => 'Joe', :age => 28) }
    let(:json) { '{"json_class":"Person","name":"Joe","age":28,"friends":null}' }

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

      it "loads nested structures from JSON" do
        json = person.to_json
        JSON.parse(json).friends.first.name.should eql 'Jane'
      end
    end
  end
end
