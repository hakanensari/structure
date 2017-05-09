class Person
  include Structure

  def initialize(data)
    @data = data
  end

  attribute(:name) do
    @data.fetch(:name)
  end
end
