class DropPerformerFavoritesTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :performer_favorites
  end
end
