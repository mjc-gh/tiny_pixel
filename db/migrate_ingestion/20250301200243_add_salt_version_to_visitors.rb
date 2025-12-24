class AddSaltVersionToVisitors < ActiveRecord::Migration[8.0]
  def change
    add_column :visitors, :salt_version, :integer, default: 0, null: false
  end
end
