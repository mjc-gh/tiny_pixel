# frozen_string_literal: true

require "test_helper"

class AdminStatCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  test "renders value in large type" do
    render_inline(AdminStatCardComponent.new(
      title: "Total Sites",
      value: 42,
      icon: "building-office-2",
      href: admin_sites_path
    ))

    assert_selector ".text-4xl.font-bold", text: "42"
  end

  test "renders title below value" do
    render_inline(AdminStatCardComponent.new(
      title: "Total Sites",
      value: 42,
      icon: "building-office-2",
      href: admin_sites_path
    ))

    assert_selector ".text-sm.text-content-secondary", text: "Total Sites"
  end

  test "renders correct icon" do
    render_inline(AdminStatCardComponent.new(
      title: "Total Sites",
      value: 42,
      icon: "building-office-2",
      href: admin_sites_path
    ))

    assert_selector "svg" # Heroicons render as SVG
  end

  test "wraps entire card in link" do
    render_inline(AdminStatCardComponent.new(
      title: "Total Users",
      value: 15,
      icon: "users",
      href: admin_users_path
    ))

    assert_selector "a[href='#{admin_users_path}']"
  end

  test "applies correct card styling classes" do
    render_inline(AdminStatCardComponent.new(
      title: "Total Sites",
      value: 42,
      icon: "building-office-2",
      href: admin_sites_path
    ))

    assert_selector "a.p-4.border.border-border.rounded.bg-surface.hover\\:border-primary"
  end
end
