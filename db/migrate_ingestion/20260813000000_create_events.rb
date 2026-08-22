# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: false do |t|
      t.text     :visitor_digest, null: false
      t.text     :name, null: false
      t.float    :value
      t.datetime :created_at, null: false
      t.text     :hostname, null: false
      t.text     :pathname, null: false
      t.text     :attribution
      t.text     :referrer

      t.index [:visitor_digest, :created_at], name: "event_created_at_idx", order: { visitor_digest: :asc, created_at: :desc }
    end
  end
end
