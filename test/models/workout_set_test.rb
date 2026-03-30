require "test_helper"

class WorkoutSetTest < ActiveSupport::TestCase
  test "assigns next position automatically" do
    workout_set = workouts(:draft_session).workout_sets.create!(
      exercise: exercises(:squat),
      target_reps: 12,
      target_weight: 24
    )

    assert_equal 3, workout_set.position
  end

  test "requires unique position within a workout" do
    workout_set = workouts(:draft_session).workout_sets.new(
      exercise: exercises(:squat),
      position: 1
    )

    assert_not workout_set.valid?
    assert_includes workout_set.errors[:position], "has already been taken"
  end

  test "normalizes coach notes" do
    workout_set = workouts(:draft_session).workout_sets.create!(
      exercise: exercises(:squat),
      position: 3,
      coach_notes: "  Stay tall at the bottom.  "
    )

    assert_equal "Stay tall at the bottom.", workout_set.coach_notes
  end

  test "marks actual logging when results are present" do
    workout_set = workouts(:active_session).workout_sets.create!(
      exercise: exercises(:bench_press),
      actual_reps: 10,
      actual_weight: 30
    )

    assert workout_set.actual_logged?
  end
end
