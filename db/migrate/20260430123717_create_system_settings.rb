class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.integer :name, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :system_settings, [:name, :value], unique: true
  end
end
