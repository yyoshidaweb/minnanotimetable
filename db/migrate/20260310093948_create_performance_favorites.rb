class CreatePerformanceFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :performance, null: false, foreign_key: true

      t.timestamps
    end
    # ユーザーと出演情報の組み合わせが重複しないようにする
    add_index :performance_favorites, [ :user_id, :performance_id ], unique: true
  end
end
