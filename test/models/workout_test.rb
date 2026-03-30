require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  test "normalizes title and notes" do
    workout = users(:one).workouts.create!(
      title: "  Upper   Body  ",
      workout_on: Date.new(2026, 3, 29),
      notes: "  Keep the pace up.  ",
      status: "draft"
    )

    assert_equal "Upper Body", workout.title
    assert_equal "Keep the pace up.", workout.notes
  end

  test "allows only one in-progress workout per user" do
    workout = users(:one).workouts.new(
      title: "Second active workout",
      workout_on: Date.new(2026, 3, 30),
      status: "in_progress"
    )

    assert_not workout.valid?
    assert_includes workout.errors[:status], "allows only one in-progress workout at a time"
  end

  test "prevents skipping from draft to completed" do
    workout = workouts(:draft_session)

    assert_not workout.update(status: "completed")
    assert_includes workout.errors[:status], "cannot transition from draft to completed"
  end

  test "discard hides workout from active scope" do
    workout = workouts(:draft_session)

    workout.discard!

    assert workout.discarded?
    assert_not_includes Workout.active, workout
  end

  test "assigns workout set positions from nested row order" do
    workout = users(:one).workouts.create!(title: "Push Day", workout_on: Date.new(2026, 3, 31), status: "draft")

    assert workout.append_planned_entries([
      { exercise_id: exercises(:lat_pulldown).id, set_count: "2", rep_pattern: "10", target_weight: "45" },
      { exercise_id: exercises(:bench_press).id, rep_pattern: "8,8,8", target_weight: "30" }
    ])

    assert_equal [ 1, 2, 3, 4, 5 ], workout.workout_sets.pluck(:position)
    assert_equal [ 10, 10, 8, 8, 8 ], workout.workout_sets.pluck(:target_reps)
  end

  test "accepts progressive rep patterns" do
    workout = users(:one).workouts.create!(title: "Push Day", workout_on: Date.new(2026, 3, 31), status: "draft")

    assert workout.append_planned_entries([
      { exercise_id: exercises(:bench_press).id, rep_pattern: "9,9,8", target_weight: "30" }
    ])

    assert_equal [ 9, 9, 8 ], workout.workout_sets.pluck(:target_reps)
  end

  test "accepts compact 3x8 style patterns" do
    workout = users(:one).workouts.create!(title: "Push Day", workout_on: Date.new(2026, 3, 31), status: "draft")

    assert workout.append_planned_entries([
      { exercise_id: exercises(:bench_press).id, rep_pattern: "3x8", target_weight: "30" }
    ])

    assert_equal [ 8, 8, 8 ], workout.workout_sets.pluck(:target_reps)
  end

  test "adds an error when a planned row misses reps" do
    workout = users(:one).workouts.create!(title: "Push Day", workout_on: Date.new(2026, 3, 31), status: "draft")

    assert_not workout.append_planned_entries([
      { exercise_id: exercises(:bench_press).id, set_count: "3", rep_pattern: "", target_weight: "30" }
    ])

    assert_includes workout.errors[:base], "Planned row 1 needs reps."
  end
end
