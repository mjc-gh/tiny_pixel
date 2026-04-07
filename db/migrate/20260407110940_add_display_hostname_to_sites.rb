# frozen_string_literal: true

class AddDisplayHostnameToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :display_hostname, :boolean, default: false, null: false
  end
end
