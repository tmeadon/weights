class AddArchivedAtToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :archived_at, :datetime
    add_index :exercises, :archived_at
  end
end
