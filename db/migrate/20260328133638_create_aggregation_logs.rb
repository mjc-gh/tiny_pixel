# frozen_string_literal: true

class CreateAggregationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :aggregation_logs do |t|
      t.references :site, null: false, foreign_key: true
      t.string :aggregation_type, null: false
      t.datetime :time_bucket, null: false
      t.integer :rows_created, default: 0, null: false
      t.integer :rows_updated, default: 0, null: false
      t.datetime :completed_at

      t.timestamps

      t.index %i[site_id aggregation_type time_bucket], name: "idx_aggregation_logs_site_type_time"
    end
  end
end
