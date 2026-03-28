# frozen_string_literal: true

class CreateWeeklyPageStats < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_page_stats do |t|
      t.references :site, null: false, foreign_key: true
      t.string :hostname, null: false
      t.string :pathname, null: false
      t.date :week_start, null: false

      t.integer :pageviews, default: 0, null: false
      t.integer :visits, default: 0, null: false
      t.integer :sessions, default: 0, null: false
      t.integer :unique_pageviews, default: 0, null: false
      t.integer :bounced_count, default: 0, null: false
      t.decimal :total_duration, precision: 12, scale: 2, default: 0.0, null: false
      t.integer :duration_count, default: 0, null: false

      t.timestamps

      t.index %i[site_id hostname pathname week_start], unique: true, name: "idx_weekly_page_stats_unique"
      t.index %i[site_id week_start], name: "idx_weekly_page_stats_site_week"
      t.index %i[site_id hostname week_start], name: "idx_weekly_page_stats_site_host_week"
    end
  end
end
