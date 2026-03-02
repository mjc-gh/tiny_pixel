class AddReferrerComponentsToPageViews < ActiveRecord::Migration[8.1]
  def change
    add_column :page_views, :referrer_hostname, :text
    add_column :page_views, :referrer_pathname, :text
  end
end
