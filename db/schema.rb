# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_10_120237) do
  create_table "aggregation_logs", force: :cascade do |t|
    t.string "aggregation_type", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "rows_created", default: 0, null: false
    t.integer "rows_updated", default: 0, null: false
    t.integer "site_id", null: false
    t.datetime "time_bucket", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "aggregation_type", "time_bucket"], name: "idx_aggregation_logs_site_type_time"
    t.index ["site_id"], name: "index_aggregation_logs_on_site_id"
  end

  create_table "daily_page_stats", force: :cascade do |t|
    t.integer "bounced_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "dimension_type", default: "global", null: false
    t.string "dimension_value"
    t.integer "duration_count", default: 0, null: false
    t.string "hostname", null: false
    t.integer "pageviews", default: 0, null: false
    t.string "pathname", null: false
    t.integer "sessions", default: 0, null: false
    t.integer "site_id", null: false
    t.decimal "total_duration", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "unique_pageviews", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visits", default: 0, null: false
    t.index ["dimension_type"], name: "idx_daily_page_stats_dimension_type"
    t.index ["site_id", "date"], name: "idx_daily_page_stats_site_date"
    t.index ["site_id", "hostname", "date"], name: "idx_daily_page_stats_site_host_date"
    t.index ["site_id", "hostname", "pathname", "dimension_type", "dimension_value", "date"], name: "idx_daily_page_stats_unique", unique: true
    t.index ["site_id"], name: "index_daily_page_stats_on_site_id"
  end

  create_table "hourly_page_stats", force: :cascade do |t|
    t.integer "bounced_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "dimension_type", default: "global", null: false
    t.string "dimension_value"
    t.integer "duration_count", default: 0, null: false
    t.string "hostname", null: false
    t.integer "pageviews", default: 0, null: false
    t.string "pathname", null: false
    t.integer "sessions", default: 0, null: false
    t.integer "site_id", null: false
    t.datetime "time_bucket", null: false
    t.decimal "total_duration", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "unique_pageviews", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visits", default: 0, null: false
    t.index ["dimension_type"], name: "idx_hourly_page_stats_dimension_type"
    t.index ["site_id", "hostname", "pathname", "dimension_type", "dimension_value", "time_bucket"], name: "idx_hourly_page_stats_unique", unique: true
    t.index ["site_id", "hostname", "time_bucket"], name: "idx_hourly_page_stats_site_host_time"
    t.index ["site_id", "time_bucket"], name: "idx_hourly_page_stats_site_time"
    t.index ["site_id"], name: "index_hourly_page_stats_on_site_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.integer "site_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["site_id"], name: "index_memberships_on_site_id"
    t.index ["user_id", "site_id"], name: "index_memberships_on_user_id_and_site_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "display_hostname", default: false, null: false
    t.string "name", null: false
    t.string "property_id", null: false
    t.string "salt", null: false
    t.integer "salt_duration", default: 0, null: false
    t.datetime "salt_last_cycled_at", null: false
    t.integer "salt_version", default: 0, null: false
    t.integer "session_timeout_minutes", default: 30
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_sites_on_property_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weekly_page_stats", force: :cascade do |t|
    t.integer "bounced_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "dimension_type", default: "global", null: false
    t.string "dimension_value"
    t.integer "duration_count", default: 0, null: false
    t.string "hostname", null: false
    t.integer "pageviews", default: 0, null: false
    t.string "pathname", null: false
    t.integer "sessions", default: 0, null: false
    t.integer "site_id", null: false
    t.decimal "total_duration", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "unique_pageviews", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visits", default: 0, null: false
    t.date "week_start", null: false
    t.index ["dimension_type"], name: "idx_weekly_page_stats_dimension_type"
    t.index ["site_id", "hostname", "pathname", "dimension_type", "dimension_value", "week_start"], name: "idx_weekly_page_stats_unique", unique: true
    t.index ["site_id", "hostname", "week_start"], name: "idx_weekly_page_stats_site_host_week"
    t.index ["site_id", "week_start"], name: "idx_weekly_page_stats_site_week"
    t.index ["site_id"], name: "index_weekly_page_stats_on_site_id"
  end

  add_foreign_key "aggregation_logs", "sites"
  add_foreign_key "daily_page_stats", "sites"
  add_foreign_key "hourly_page_stats", "sites"
  add_foreign_key "memberships", "sites"
  add_foreign_key "memberships", "users"
  add_foreign_key "weekly_page_stats", "sites"
end
