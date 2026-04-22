class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    # usersテーブルにroleカラムを追加（デフォルトは無料ユーザー）
    add_column :users, :role, :integer, null: false, default: 0
  end
end
