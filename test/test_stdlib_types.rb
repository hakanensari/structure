# frozen_string_literal: true

require_relative "helper"
require "structure"
require "date"
require "time"
require "uri"

class TestStdlibTypes < Minitest::Test
  def test_date_coercion
    event_class = Structure.new do
      attribute(:event_date, Date)
    end

    event = event_class.parse(event_date: "2024-12-25")

    assert_instance_of(Date, event.event_date)
    assert_equal(Date.new(2024, 12, 25), event.event_date)
  end

  def test_datetime_coercion
    event_class = Structure.new do
      attribute(:starts_at, DateTime)
    end

    event = event_class.parse(starts_at: "2024-12-25T10:30:00+00:00")

    assert_instance_of(DateTime, event.starts_at)
    assert_equal(DateTime.new(2024, 12, 25, 10, 30, 0, "+00:00"), event.starts_at)
  end

  def test_time_coercion
    event_class = Structure.new do
      attribute(:created_at, Time)
    end

    event = event_class.parse(created_at: "2024-12-25 10:30:00")

    assert_instance_of(Time, event.created_at)
    assert_equal(2024, event.created_at.year)
    assert_equal(12, event.created_at.month)
    assert_equal(25, event.created_at.day)
    assert_equal(10, event.created_at.hour)
    assert_equal(30, event.created_at.min)
  end

  def test_uri_coercion
    api_class = Structure.new do
      attribute(:endpoint, URI)
    end

    api = api_class.parse(endpoint: "https://api.example.com/v1/users")

    assert_instance_of(URI::HTTPS, api.endpoint)
    assert_equal("api.example.com", api.endpoint.host)
    assert_equal("/v1/users", api.endpoint.path)
  end

  def test_date_array_coercion
    calendar_class = Structure.new do
      attribute(:holidays, [Date])
    end

    calendar = calendar_class.parse(holidays: ["2024-12-25", "2024-01-01", "2024-07-04"])

    assert_equal(3, calendar.holidays.length)
    assert(calendar.holidays.all? { |d| d.is_a?(Date) })
    assert_equal(Date.new(2024, 12, 25), calendar.holidays[0])
    assert_equal(Date.new(2024, 1, 1), calendar.holidays[1])
    assert_equal(Date.new(2024, 7, 4), calendar.holidays[2])
  end

  def test_nil_date_handling
    event_class = Structure.new do
      attribute(:date, Date)
    end

    event = event_class.parse(date: nil)

    assert_nil(event.date)
  end

  def test_invalid_date_raises_error
    event_class = Structure.new do
      attribute(:date, Date)
    end

    assert_raises(Date::Error) do
      event_class.parse(date: "not-a-date")
    end
  end
end
