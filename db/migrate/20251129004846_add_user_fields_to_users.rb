class AddUserFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # 名前と説明欄、ユーザー名
    add_column :users, :name, :string, null: false, default: "", limit: 50
    add_column :users, :description, :text
    add_column :users, :username, :string, null: false, default: "", limit: 50

    # Omniauth関連
    add_column :users, :provider, :string, null: false, default: "", limit: 50
    add_column :users, :uid, :string, null: false, default: "", limit: 255

    # ユニーク制約
    add_index  :users, [ :provider, :uid ], unique: true
    add_index  :users, :username, unique: true
  end
end
