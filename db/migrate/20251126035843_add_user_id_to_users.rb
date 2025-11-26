class AddUserIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_id, :string, null: false
    add_index :users, :user_id, unique: true
  end
end
