# frozen_string_literal: true

class Person
  include Structure

  attr_reader :data

  def initialize(data)
    @data = data
  end

  attribute(:name) do
    data.fetch(:name)
  end
end
