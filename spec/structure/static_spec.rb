require 'spec_helper'

class Structure
  describe "A static structure" do
    it "is enumerable" do
      City.should be_an Enumerable
    end

    describe ".all" do
      it "returns all records" do
        City.all.should have(2).cities
      end
    end

    describe ".find" do
      it "finds a record by its id" do
        City.find(1).should be_a City
      end

      it "returns nil if the record does not exist" do
        City.find(4).should be_nil
      end
    end

    describe ".set_data_path" do
      it "sets the data path" do
        City.set_data_path("foo")
        City.send(:data_path).should eql "foo"
      end
    end

    context "when sourced data does not include ids" do
      before(:all) do
        City.instance_variable_set(:@all, nil)
        fixture = File.expand_path("../../fixtures/cities_without_id.yml", __FILE__) 
        City.set_data_path(fixture)
      end

      it "should auto-increment the ids of loaded records" do
        City.map(&:id).should =~ [1, 2, 3]
      end

      describe ".increment_id" do
        before do
          City.instance_variable_set(:@increment_id, nil)
        end

        it "starts from 1" do
          City.send(:increment_id).should eql 1
        end

        it "auto-increments" do
          City.send(:increment_id)
          City.send(:increment_id).should eql 2
        end
      end
    end
  end
end
