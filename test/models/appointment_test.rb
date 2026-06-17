require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(first_name: "A", last_name: "B", username: "appt", email: "appt@e.com", password: "password1")
    @service = Service.create!(name: "Boxing & Conditioning", category: "Boxing", duration_min: 45)
  end

  test "cannot be booked in the past" do
    appt = @user.appointments.new(service: @service, scheduled_at: 1.day.ago)
    assert_not appt.valid?
    assert_includes appt.errors[:scheduled_at], "can't be in the past"
  end

  test "inherits duration from service and computes end time" do
    appt = @user.appointments.create!(service: @service, scheduled_at: 2.days.from_now)
    assert_equal 45, appt.duration_min
    assert_equal appt.scheduled_at + 45.minutes, appt.ends_at
  end

  test "upcoming scope excludes cancelled and past" do
    future = @user.appointments.create!(service: @service, scheduled_at: 2.days.from_now)
    @user.appointments.create!(service: @service, scheduled_at: 3.days.from_now, status: "cancelled")
    assert_includes Appointment.upcoming, future
    assert_equal 1, Appointment.upcoming.count
  end

  test "generates an iCalendar payload" do
    appt = @user.appointments.create!(service: @service, scheduled_at: 2.days.from_now, mode: "virtual",
                                      meeting_url: "https://meet.example.com/x")
    ics = appt.to_ics
    assert_match "BEGIN:VCALENDAR", ics
    assert_match "Boxing & Conditioning", ics
    assert_match "https://meet.example.com/x", ics
  end
end
