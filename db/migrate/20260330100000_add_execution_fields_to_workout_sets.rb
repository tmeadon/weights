class AddExecutionFieldsToWorkoutSets < ActiveRecord::Migration[8.1]
  def change
    change_table :workout_sets, bulk: true do |t|
      t.decimal :actual_weight, precision: 8, scale: 2
      t.integer :actual_reps
      t.decimal :actual_rpe, precision: 3, scale: 1
    end
  end
end
