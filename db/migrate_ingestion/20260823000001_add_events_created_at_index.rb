# frozen_string_literal: true

class AddEventsCreatedAtIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :events, :created_at, name: "events_created_at_idx"
  end
end
