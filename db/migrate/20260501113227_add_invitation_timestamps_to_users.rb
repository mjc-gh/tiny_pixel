class AddInvitationTimestampsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :invited_at, :datetime
    add_column :users, :invitation_completed_at, :datetime
  end
end
