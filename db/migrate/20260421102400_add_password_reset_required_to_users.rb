# frozen_string_literal: true

class AddPasswordResetRequiredToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_reset_required, :boolean, null: false, default: false
  end
end
