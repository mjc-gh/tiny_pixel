class CreateSites < ActiveRecord::Migration[8.0]
  def change
    create_table :sites do |t|
      t.string   :property_id, null: false
      t.string   :name, null: false

      t.string   :salt, null: false
      t.integer  :salt_duration, default: 0, null: false
      t.datetime :salt_last_cycled_at, null: false

      t.timestamps

      t.index [:property_id], unique: true
    end
  end
end
