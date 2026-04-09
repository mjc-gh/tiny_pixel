# frozen_string_literal: true

class AddDimensionToPageStats < ActiveRecord::Migration[8.1]
  def change
    # Add non-nullable dimension column with default "global" to all three tables
    add_column :hourly_page_stats, :dimension, :string, null: false, default: "global"
    add_column :daily_page_stats, :dimension, :string, null: false, default: "global"
    add_column :weekly_page_stats, :dimension, :string, null: false, default: "global"

    # Update unique indexes to include dimension
    # Old: [site_id, hostname, pathname, time_bucket]
    # New: [site_id, hostname, pathname, dimension, time_bucket]

    remove_index :hourly_page_stats, name: "idx_hourly_page_stats_unique"
    add_index :hourly_page_stats,
              %i[site_id hostname pathname dimension time_bucket],
              unique: true,
              name: "idx_hourly_page_stats_unique"

    remove_index :daily_page_stats, name: "idx_daily_page_stats_unique"
    add_index :daily_page_stats,
              %i[site_id hostname pathname dimension date],
              unique: true,
              name: "idx_daily_page_stats_unique"

    remove_index :weekly_page_stats, name: "idx_weekly_page_stats_unique"
    add_index :weekly_page_stats,
              %i[site_id hostname pathname dimension week_start],
              unique: true,
              name: "idx_weekly_page_stats_unique"

    # Add indexes for dimension queries
    add_index :hourly_page_stats, :dimension, name: "idx_hourly_page_stats_dimension"
    add_index :daily_page_stats, :dimension, name: "idx_daily_page_stats_dimension"
    add_index :weekly_page_stats, :dimension, name: "idx_weekly_page_stats_dimension"
  end
end
