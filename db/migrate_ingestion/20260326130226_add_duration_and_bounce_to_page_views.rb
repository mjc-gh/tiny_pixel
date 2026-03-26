# frozen_string_literal: true

class AddDurationAndBounceToPageViews < ActiveRecord::Migration[8.1]
  def change
    add_column :page_views, :duration, :integer
    add_column :page_views, :bounced, :boolean, default: true

    add_index :page_views, [:visitor_digest, :created_at, :bounced],
              name: "page_views_bounce_analytics_idx"
  end
end
