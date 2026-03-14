class AddRememberTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :remember_token, :string
    # 追加した remember_token カラムを一意に指定
    add_index :users, :remember_token, unique: true
  end
end
