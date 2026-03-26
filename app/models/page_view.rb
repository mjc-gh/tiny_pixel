# frozen_string_literal: true

# == Schema Information
#
# Table name: page_views
# Database name: ingestion
#
#  attribution       :text
#  bounced           :boolean          default(TRUE)
#  digest            :text             not null
#  duration          :integer
#  hostname          :text             not null
#  is_unique         :boolean          default(FALSE), not null
#  new_session       :boolean          default(FALSE), not null
#  new_visit         :boolean          default(FALSE), not null
#  pathname          :text             not null
#  referrer          :text
#  referrer_hostname :text
#  referrer_pathname :text
#  visitor_digest    :text             not null
#  created_at        :datetime         not null
#
# Indexes
#
#  page_view_created_at_idx          (visitor_digest,created_at DESC)
#  page_views_bounce_analytics_idx   (visitor_digest,created_at,bounced)
#  page_views_uniq_idx               (visitor_digest,digest,created_at) UNIQUE
#  page_views_visitor_path_time_idx  (visitor_digest,pathname,created_at)
#
class PageView < AnalyticsRecord
  belongs_to :visitor, foreign_key: :visitor_digest, primary_key: :digest
end
