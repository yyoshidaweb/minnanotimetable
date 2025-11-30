class CreatePerformerFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :performer_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :performer, null: false, foreign_key: true

      t.timestamps
    end
    # ユーザーと出演者の組み合わせが重複しないようにする
    add_index :performer_favorites, [ :user_id, :performer_id ], unique: true
  end
end
