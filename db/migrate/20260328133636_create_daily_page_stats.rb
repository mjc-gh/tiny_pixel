# frozen_string_literal: true

class CreateDailyPageStats < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_page_stats do |t|
      t.references :site, null: false, foreign_key: true
      t.string :hostname, null: false
      t.string :pathname, null: false
      t.date :date, null: false

      t.integer :pageviews, default: 0, null: false
      t.integer :visits, default: 0, null: false
      t.integer :sessions, default: 0, null: false
      t.integer :unique_pageviews, default: 0, null: false
      t.integer :bounced_count, default: 0, null: false
      t.decimal :total_duration, precision: 12, scale: 2, default: 0.0, null: false
      t.integer :duration_count, default: 0, null: false

      t.timestamps

      t.index %i[site_id hostname pathname date], unique: true, name: "idx_daily_page_stats_unique"
      t.index %i[site_id date], name: "idx_daily_page_stats_site_date"
      t.index %i[site_id hostname date], name: "idx_daily_page_stats_site_host_date"
    end
  end
end
