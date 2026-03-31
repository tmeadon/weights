class AddPlannedTotalDifficultyToWorkouts < ActiveRecord::Migration[8.1]
  def change
    add_column :workouts, :planned_total_difficulty, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
