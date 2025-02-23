class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views, id: false do |t|
      t.text     :visitor_digest, null: false
      t.text     :digest, null: false

      t.datetime :created_at, null: false

      t.text     :hostname, null: false
      t.text     :pathname, null: false
      t.boolean  :new_visit, default: false, null: false
      t.boolean  :new_session, default: false, null: false
      t.text     :attribution
      t.text     :referrer

      t.index [:visitor_digest, :digest, :created_at], name: "page_views_uniq_idx", unique: true
      t.index [:visitor_digest, :created_at], name: "page_view_created_at_idx", order: { visitor_digest: :asc, created_at: :desc }
    end
  end
end
