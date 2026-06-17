require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "auto-generates a slug from the name" do
    service = Service.create!(name: "Pelvic Health Therapy", category: "Pelvic Health")
    assert_equal "pelvic-health-therapy", service.slug
    assert_equal "pelvic-health-therapy", service.to_param
  end

  test "formats price from cents" do
    assert_equal "$75", Service.new(price_cents: 7500).price
    assert_equal "Free", Service.new(price_cents: 0).price
  end

  test "active scope filters hidden services" do
    on = Service.create!(name: "On", category: "Boxing", active: true)
    Service.create!(name: "Off", category: "Boxing", active: false)
    assert_includes Service.active, on
    assert_equal 1, Service.active.count
  end
end
