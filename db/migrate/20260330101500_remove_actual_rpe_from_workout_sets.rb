class RemoveActualRpeFromWorkoutSets < ActiveRecord::Migration[8.1]
  def change
    remove_column :workout_sets, :actual_rpe, :decimal
  end
end
