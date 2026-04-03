class AddWorkoutTypeToWorkouts < ActiveRecord::Migration[8.1]
  def change
    add_column :workouts, :workout_type, :string
    add_index :workouts, [ :user_id, :workout_type ]
  end
end
