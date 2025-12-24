# frozen_string_literal: true

class PageView < AnalyticsRecord
  belongs_to :visitor, foreign_key: :visitor_digest, primary_key: :digest
end
