# frozen_string_literal: true

class Visitor < AnalyticsRecord
  has_many :page_views, foreign_key: :visitor_digest, primary_key: :digest

  enum :device_type, {
    desktop: 1,
    mobile: 2,
    crawler: 9,
    other: 10,
  }, scopes: false, prefix: true

  enum :browser, {
    chrome: 1,
    edge: 2,
    safari: 3,
    firefox: 4,
    opera: 5,
    other: 999,
  }, scopes: false, prefix: true
end
