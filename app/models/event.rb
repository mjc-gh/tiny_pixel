# frozen_string_literal: true

# == Schema Information
#
# Table name: events
# Database name: ingestion
#
#  attribution    :text
#  hostname       :text             not null
#  name           :text             not null
#  pathname       :text             not null
#  referrer       :text
#  value          :float
#  visitor_digest :text             not null
#  created_at     :datetime         not null
#
# Indexes
#
#  event_created_at_idx   (visitor_digest,created_at DESC)
#  events_created_at_idx  (created_at)
#
class Event < AnalyticsRecord
  belongs_to :visitor, foreign_key: :visitor_digest, primary_key: :digest
end
