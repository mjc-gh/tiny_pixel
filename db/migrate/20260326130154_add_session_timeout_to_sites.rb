# frozen_string_literal: true

class AddSessionTimeoutToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :session_timeout_minutes, :integer, default: 30
  end
end
