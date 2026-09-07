# frozen_string_literal: true

class CreateEventStats < ActiveRecord::Migration[8.1]
  STAT_TABLES = {
    hourly_event_stats: :time_bucket,
    daily_event_stats: :date,
    weekly_event_stats: :week_start
  }.freeze

  def change
    STAT_TABLES.each do |table, time_column|
      create_table table do |t|
        t.references :site, null: false, foreign_key: true
        t.string :name, null: false
        t.string :hostname, null: false
        t.string :pathname, null: false
        t.public_send(time_column == :time_bucket ? :datetime : :date, time_column, null: false)
        t.integer :hits, default: 0, null: false
        t.integer :unique_hits, default: 0, null: false
        t.timestamps

        t.index %i[site_id name hostname pathname] + [time_column], unique: true,
          name: "idx_#{table}_unique"
        t.index %i[site_id] + [time_column], name: "idx_#{table}_site_time"
        t.index %i[site_id name] + [time_column], name: "idx_#{table}_site_name_time"
        t.index %i[site_id hostname] + [time_column], name: "idx_#{table}_site_host_time"
      end
    end
  end
end
