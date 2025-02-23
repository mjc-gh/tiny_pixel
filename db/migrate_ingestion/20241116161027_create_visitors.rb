class CreateVisitors < ActiveRecord::Migration[8.0]
  def change
    create_table :visitors, id: false do |t|
      t.text     :digest, null: false

      t.integer  :property_id, null: false
      t.integer  :device_type, null: false
      t.integer  :browser, null: false
      t.string   :country, null: false

      t.index    :digest, unique: true
    end
  end
end
