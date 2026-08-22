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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_000000) do
  create_table "events", id: false, force: :cascade do |t|
    t.text "attribution"
    t.datetime "created_at", null: false
    t.text "hostname", null: false
    t.text "name", null: false
    t.text "pathname", null: false
    t.text "referrer"
    t.float "value"
    t.text "visitor_digest", null: false
    t.index ["visitor_digest", "created_at"], name: "event_created_at_idx", order: { created_at: :desc }
  end

  create_table "page_views", id: false, force: :cascade do |t|
    t.text "attribution"
    t.boolean "bounced", default: true
    t.datetime "created_at", null: false
    t.text "digest", null: false
    t.integer "duration"
    t.text "hostname", null: false
    t.boolean "is_unique", default: false, null: false
    t.boolean "new_session", default: false, null: false
    t.boolean "new_visit", default: false, null: false
    t.text "pathname", null: false
    t.text "ref"
    t.text "referrer"
    t.text "referrer_hostname"
    t.text "referrer_pathname"
    t.text "utm_campaign"
    t.text "utm_content"
    t.text "utm_medium"
    t.text "utm_source"
    t.text "utm_term"
    t.text "visitor_digest", null: false
    t.index ["visitor_digest", "created_at", "bounced"], name: "page_views_bounce_analytics_idx"
    t.index ["visitor_digest", "created_at"], name: "page_view_created_at_idx", order: { created_at: :desc }
    t.index ["visitor_digest", "digest", "created_at"], name: "page_views_uniq_idx", unique: true
    t.index ["visitor_digest", "pathname", "created_at"], name: "page_views_visitor_path_time_idx"
  end

  create_table "visitors", id: false, force: :cascade do |t|
    t.integer "browser", null: false
    t.string "country", null: false
    t.integer "device_type", null: false
    t.text "digest", null: false
    t.integer "property_id", null: false
    t.integer "salt_version", default: 0, null: false
    t.index ["digest"], name: "index_visitors_on_digest", unique: true
  end
end
