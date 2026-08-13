class WorkoutExerciseBest < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise

  def current_summary
    workout.summarize_recent_logged_sets(workout.workout_sets.select { |workout_set| workout_set.exercise_id == exercise_id })
  end

  def previous_row
    return @previous_row if defined?(@previous_row)
    return @previous_row = nil if personal_best_previous_value.blank?

    @previous_row = workout.previous_personal_best_row_for_exercise(exercise_id, previous_best_value: personal_best_previous_value)
  end

  def previous_label
    previous = previous_row
    return if previous.blank?

    previous.current_summary
  end
end
