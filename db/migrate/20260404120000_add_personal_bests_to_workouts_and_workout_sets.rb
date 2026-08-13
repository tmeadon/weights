class AddPersonalBestsToWorkoutsAndWorkoutSets < ActiveRecord::Migration[8.1]
  def up
    add_column :workouts, :personal_best_count, :integer, null: false, default: 0

    add_column :workout_sets, :personal_best, :boolean, null: false, default: false
    add_column :workout_sets, :personal_best_value, :decimal, precision: 10, scale: 2
    add_column :workout_sets, :personal_best_previous_value, :decimal, precision: 10, scale: 2

    add_index :workout_sets, [ :exercise_id, :personal_best ]

    backfill_personal_bests
  end

  def down
    remove_index :workout_sets, [ :exercise_id, :personal_best ]

    remove_column :workout_sets, :personal_best_previous_value
    remove_column :workout_sets, :personal_best_value
    remove_column :workout_sets, :personal_best
    remove_column :workouts, :personal_best_count
  end

  private
    def backfill_personal_bests
      execute "UPDATE workout_sets SET personal_best = 0, personal_best_value = NULL, personal_best_previous_value = NULL"
      execute "UPDATE workouts SET personal_best_count = 0"

      user_ids = Workout.where(deleted_at: nil).distinct.pluck(:user_id)

      user_ids.each do |user_id|
        workout = Workout.where(user_id:, deleted_at: nil).order(:id).first
        next unless workout

        exercise_ids = WorkoutSet.joins(:workout)
          .where(workouts: { user_id:, deleted_at: nil })
          .where.not(actual_reps: nil)
          .where.not(actual_weight: nil)
          .distinct
          .pluck(:exercise_id)

        exercise_ids.each do |exercise_id|
          workout.recalculate_personal_bests_for_exercise!(exercise_id, affected_workout_ids: Workout.where(user_id:, deleted_at: nil).pluck(:id))
        end
      end
    end
end
