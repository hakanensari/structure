require 'spec_helper'

describe Structure do
  let(:person) { Person.new }

  it "is enumerable" do
    person.should respond_to :map
  end

  describe ".key" do
    it "defines accessors" do
      %w{name name=}.each { |method| person.should respond_to method }
    end

    context "when a key name clashes with a method name" do
      it "raises an error" do
        expect do
          Person.key :class
        end.to raise_error NameError
      end
    end

    context "when an invalid type is specified" do
      it "raises an error" do
        expect do
          Person.key :location, :type => Object
        end.to raise_error TypeError
      end
    end

    context "when default value is not of the specified type" do
      it "raises an error" do
        expect do
          Person.key :location, :type => String, :default => 0
        end.to raise_error TypeError
      end
    end
  end

  describe ".default_attributes" do
    it "returns the default attributes for the structure" do
      Person.send(:default_attributes).should == { :name    => nil,
                                                   :age     => nil,
                                                   :friends => [] }
      Book.send(:default_attributes).should == { :title   => nil,
                                                 :authors => nil }
    end
  end

  describe "attribute getter" do
    it "returns the value of the attribute" do
      person.instance_variable_get(:@attributes)[:name] = 'Joe'
      person.name.should eql 'Joe'
    end

    context "when type is Array and default value is []" do
      let(:friend) { Person.new }

      it "supports the `<<' idiom" do
        person.friends << friend
        person.friends.count.should eql 1
        friend.friends.count.should eql 0
      end
    end
  end

  describe "attribute setter" do
    it "sets the value of the attribute" do
      person.name = "Joe"
      person.instance_variable_get(:@attributes)[:name].should eql 'Joe'
    end

    context "when a type is specified" do
      it "casts the value" do
        person.age = "28"
        person.age.should be_an Integer
      end
    end

    context "when a type is not specified" do
      it "casts to String" do
        person.name = 123
        person.name.should be_a String
      end
    end

    context "when type is Boolean" do
      context "when default value is true" do
        it "does not raise an invalid type error" do
          expect do
            Person.key :single, :type => Boolean, :default => true
          end.not_to raise_error
        end
      end

      context "when default value is false" do
        it "does not raise an invalid type error" do
          expect do
            Person.key :married, :type => Boolean, :default => false
          end.not_to raise_error
        end
      end

      context "when typecasting a set value" do
        before(:all) do
          Person.key :vegetarian, :type => Boolean
        end

        it "typecasts 'true' to true" do
          person.vegetarian = 'true'
          person.vegetarian.should be_true
        end

        it "typecasts 'TRUE' to true" do
          person.vegetarian = 'TRUE'
          person.vegetarian.should be_true
        end

        it "typecasts '1' to true" do
          person.vegetarian = '1'
          person.vegetarian.should be_true
        end

        it "typecasts all other strings to false" do
          person.vegetarian = 'foo'
          person.vegetarian.should be_false
        end

        it "typecasts 0 to false" do
          person.vegetarian = 0
          person.vegetarian.should be_false
        end

        it "typecasts all other integers to true" do
          person.vegetarian = 1
          person.vegetarian.should be_true
        end
      end
    end

    context "when type is Hash" do
      before(:all) do
        Person.key :education, :type => Hash
      end

      context "when setting to a value that is not a Hash" do
        it "raises an error" do
          expect do
            person.education = 'foo'
          end.to raise_error TypeError
        end
      end
    end

    context "when type is Structure" do
      before(:all) do
        Person.has_one :father
      end

      context "when setting to a value that is not a Structure" do
        it "raises an error" do
          expect do
            person.father = 'foo'
          end.to raise_error TypeError
        end
      end
    end

    context "when a default is specified" do
      it "defaults to that value" do
        Person.key :location, :default => 'New York'
        person.location.should eql 'New York'
      end
    end

    context "when a default is not specified" do
      it "defaults to nil" do
        person.age.should be_nil
      end
    end

    context "when setting the value of an attribute to nil" do
      it "does not typecast the value" do
        person.age = nil
        person.age.should be_a NilClass
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
