# frozen_string_literal: true

class SplitDimensionColumn < ActiveRecord::Migration[8.1]
  def change
    # Add new columns to all three stat tables
    add_column :hourly_page_stats, :dimension_type, :string, null: false, default: "global"
    add_column :hourly_page_stats, :dimension_value, :string

    add_column :daily_page_stats, :dimension_type, :string, null: false, default: "global"
    add_column :daily_page_stats, :dimension_value, :string

    add_column :weekly_page_stats, :dimension_type, :string, null: false, default: "global"
    add_column :weekly_page_stats, :dimension_value, :string

    # Data migration: parse existing dimension values
    reversible do |dir|
      dir.up do
        migrate_dimension_data_up
      end

      dir.down do
        # On rollback, just drop the columns (data will be lost but old dimension column is preserved)
      end
    end

    # Remove old unique indexes
    remove_index :hourly_page_stats, name: "idx_hourly_page_stats_unique"
    remove_index :daily_page_stats, name: "idx_daily_page_stats_unique"
    remove_index :weekly_page_stats, name: "idx_weekly_page_stats_unique"

    # Add new unique indexes with new columns
    add_index :hourly_page_stats,
              %i[site_id hostname pathname dimension_type dimension_value time_bucket],
              unique: true,
              name: "idx_hourly_page_stats_unique"

    add_index :daily_page_stats,
              %i[site_id hostname pathname dimension_type dimension_value date],
              unique: true,
              name: "idx_daily_page_stats_unique"

    add_index :weekly_page_stats,
              %i[site_id hostname pathname dimension_type dimension_value week_start],
              unique: true,
              name: "idx_weekly_page_stats_unique"

    # Add indexes on dimension_type for filtering
    add_index :hourly_page_stats, :dimension_type, name: "idx_hourly_page_stats_dimension_type"
    add_index :daily_page_stats, :dimension_type, name: "idx_daily_page_stats_dimension_type"
    add_index :weekly_page_stats, :dimension_type, name: "idx_weekly_page_stats_dimension_type"

    # Remove old dimension column and its index
    remove_index :hourly_page_stats, name: "idx_hourly_page_stats_dimension"
    remove_column :hourly_page_stats, :dimension

    remove_index :daily_page_stats, name: "idx_daily_page_stats_dimension"
    remove_column :daily_page_stats, :dimension

    remove_index :weekly_page_stats, name: "idx_weekly_page_stats_dimension"
    remove_column :weekly_page_stats, :dimension
  end

  private

  def migrate_dimension_data_up
    # Migrate HourlyPageStat
    execute(<<~SQL)
      UPDATE hourly_page_stats
      SET dimension_type = CASE
        WHEN dimension = 'global' THEN 'global'
        ELSE SUBSTR(dimension, 1, INSTR(dimension, ':') - 1)
      END,
      dimension_value = CASE
        WHEN dimension = 'global' THEN NULL
        ELSE SUBSTR(dimension, INSTR(dimension, ':') + 1)
      END
    SQL

    # Migrate DailyPageStat
    execute(<<~SQL)
      UPDATE daily_page_stats
      SET dimension_type = CASE
        WHEN dimension = 'global' THEN 'global'
        ELSE SUBSTR(dimension, 1, INSTR(dimension, ':') - 1)
      END,
      dimension_value = CASE
        WHEN dimension = 'global' THEN NULL
        ELSE SUBSTR(dimension, INSTR(dimension, ':') + 1)
      END
    SQL

    # Migrate WeeklyPageStat
    execute(<<~SQL)
      UPDATE weekly_page_stats
      SET dimension_type = CASE
        WHEN dimension = 'global' THEN 'global'
        ELSE SUBSTR(dimension, 1, INSTR(dimension, ':') - 1)
      END,
      dimension_value = CASE
        WHEN dimension = 'global' THEN NULL
        ELSE SUBSTR(dimension, INSTR(dimension, ':') + 1)
      END
    SQL
  end
end
