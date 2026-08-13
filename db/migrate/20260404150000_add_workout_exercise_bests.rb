class AddWorkoutExerciseBests < ActiveRecord::Migration[8.1]
  def up
    create_table :workout_exercise_bests do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.decimal :personal_best_value, precision: 10, scale: 2, null: false
      t.decimal :personal_best_previous_value, precision: 10, scale: 2
      t.timestamps
    end

    add_index :workout_exercise_bests, [ :workout_id, :exercise_id ], unique: true

    backfill_workout_exercise_bests
  end

  def down
    drop_table :workout_exercise_bests
  end

  private
    def backfill_workout_exercise_bests
      WorkoutExerciseBest.reset_column_information
      Workout.reset_column_information
      WorkoutSet.reset_column_information

      WorkoutExerciseBest.delete_all

      User.find_each do |user|
        bests_by_exercise = Hash.new { |hash, key| hash[key] = BigDecimal("0") }
        rows = []

        user.workouts.active
          .where(deleted_at: nil)
          .order(workout_on: :asc, created_at: :asc)
          .includes(workout_sets: :exercise)
          .each do |workout|
          workout.workout_sets.select(&:actual_logged?).group_by(&:exercise_id).each do |exercise_id, sets|
            total = sets.sum { |workout_set| workout_set.actual_difficulty.to_d }
            next unless total > bests_by_exercise[exercise_id]

            rows << {
              workout_id: workout.id,
              exercise_id:,
              personal_best_value: total,
              personal_best_previous_value: bests_by_exercise[exercise_id].zero? ? nil : bests_by_exercise[exercise_id],
              created_at: Time.current,
              updated_at: Time.current
            }
            bests_by_exercise[exercise_id] = total
          end
        end

        WorkoutExerciseBest.insert_all!(rows) if rows.any?
      end

      update_personal_best_counts
    end

    def update_personal_best_counts
      counts_by_workout_id = WorkoutExerciseBest.group(:workout_id).count
      Workout.active.find_each do |workout|
        workout.update_column(:personal_best_count, counts_by_workout_id[workout.id] || 0)
      end
    end
end
