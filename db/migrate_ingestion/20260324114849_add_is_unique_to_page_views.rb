class AddIsUniqueToPageViews < ActiveRecord::Migration[8.0]
  def change
    add_column :page_views, :is_unique, :boolean, default: false, null: false
    add_index :page_views, [:visitor_digest, :pathname, :created_at],
              name: "page_views_visitor_path_time_idx"
  end
end
