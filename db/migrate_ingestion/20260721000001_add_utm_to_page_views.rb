# frozen_string_literal: true

class AddUtmToPageViews < ActiveRecord::Migration[8.1]
  def change
    add_column :page_views, :ref, :text unless column_exists?(:page_views, :ref)
    add_column :page_views, :utm_source, :text unless column_exists?(:page_views, :utm_source)
    add_column :page_views, :utm_medium, :text unless column_exists?(:page_views, :utm_medium)
    add_column :page_views, :utm_campaign, :text unless column_exists?(:page_views, :utm_campaign)
    add_column :page_views, :utm_content, :text unless column_exists?(:page_views, :utm_content)
    add_column :page_views, :utm_term, :text unless column_exists?(:page_views, :utm_term)
  end
end
