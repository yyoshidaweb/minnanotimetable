class AddAdmissionRestrictedToStages < ActiveRecord::Migration[8.1]
  def change
    add_column :stages, :admission_restricted, :boolean, null: false, default: false
  end
end
