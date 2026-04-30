class AddStatsRetentionToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :stats_retention_unit, :integer, default: 2, null: false
    add_column :sites, :stats_retention_duration, :integer, default: 12, null: false
  end
end
