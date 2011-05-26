require 'spec_helper'

describe Structure do
  let(:person) { Person.new }

  it "is enumerable" do
    person.name ="Joe"
    person.map { |key, value| value }.should include "Joe"
  end

  context "when object is frozen" do
    before do
      person.freeze
    end

    it "raises an error" do
      expect do
        person.name = 'Joe'
      end.to raise_error TypeError
    end
  end

  describe ".key" do
    it "defines accessors" do
      %w{name name=}.each { |method| person.should respond_to method }
    end

    context "when name clashes with an existing method" do
      it "raises an error" do
        expect do
          Person.key :name
        end.to raise_error NameError
      end
    end

    context "when a type is specified" do
      context "when setting the attribute to a non-nil value" do
        it "casts the value" do
          person.age = "28"
          person.age.should eql 28
        end
      end

      context "when setting the attribute to nil" do
        it "does not set the value" do
          person.age = nil
          person.age.should be_nil
        end
      end
    end
  end

  describe ".new" do
    context "when attributes are specified" do
      it "initializes the object with those attributes" do
        jane = Person.new(:name => 'Jane', :age => "29")
        jane.name.should eql 'Jane'
        jane.age.should eql 29
      end
    end
  end
end
