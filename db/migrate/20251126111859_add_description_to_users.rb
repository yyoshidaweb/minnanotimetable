class AddDescriptionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :description, :text
  end
end
