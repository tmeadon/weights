require "test_helper"

class WorkoutSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workout = workouts(:draft_session)
    @workout_set = workout_sets(:draft_bench)
    sign_in_as(@user)
  end

  test "create workout sets from a single exercise block" do
    assert_difference("WorkoutSet.count", 3) do
      post workout_workout_sets_path(@workout), params: {
        planned_entry: {
          exercise_id: exercises(:squat).id,
          set_count: 3,
          rep_pattern: "8",
          target_weight: 24,
          coach_notes: "Drive knees forward."
        }
      }
    end

    assert_redirected_to workout_path(@workout)
    assert_equal [ 8, 8, 8 ], @workout.workout_sets.reload.last(3).map(&:target_reps)
  end

  test "create workout sets with progressive reps" do
    assert_difference("WorkoutSet.count", 3) do
      post workout_workout_sets_path(@workout), params: {
        planned_entry: {
          exercise_id: exercises(:squat).id,
          set_count: "",
          rep_pattern: "9,9,8",
          target_weight: 24,
          coach_notes: "Controlled tempo"
        }
      }
    end

    assert_redirected_to workout_path(@workout)
    assert_equal [ 9, 9, 8 ], @workout.workout_sets.reload.last(3).map(&:target_reps)
  end

  test "remove exercise removes all planned sets for that exercise" do
    assert_difference("WorkoutSet.count", -1) do
      delete remove_exercise_workout_workout_sets_path(@workout, exercise_id: exercises(:bench_press).id)
    end

    assert_redirected_to workout_path(@workout)
    assert_not @workout.workout_sets.reload.exists?(exercise_id: exercises(:bench_press).id)
  end

  test "invalid planned entry re-renders workout show" do
    assert_no_difference("WorkoutSet.count") do
      post workout_workout_sets_path(@workout), params: {
        planned_entry: {
          exercise_id: exercises(:squat).id,
          set_count: 3,
          rep_pattern: "",
          target_weight: 24,
          coach_notes: "Missing reps"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".flash", /needs reps/i
    assert_select ".panel-label", "Add sets"
  end

  test "edit" do
    get edit_workout_workout_set_path(@workout, @workout_set)

    assert_response :success
    assert_select "h1", "Edit planned set"
  end

  test "update workout set" do
    patch workout_workout_set_path(@workout, @workout_set), params: {
      workout_set: {
        target_reps: 9,
        coach_notes: "Pause at the chest."
      }
    }

    assert_redirected_to workout_path(@workout)
    assert_equal 9, @workout_set.reload.target_reps
    assert_equal "Pause at the chest.", @workout_set.coach_notes
  end

  test "destroy workout set and reorder remaining positions" do
    assert_difference("WorkoutSet.count", -1) do
      delete workout_workout_set_path(@workout, @workout_set)
    end

    assert_redirected_to workout_path(@workout)
    assert_equal [ 1 ], @workout.workout_sets.reload.pluck(:position)
  end

  test "requires authentication" do
    sign_out

    post workout_workout_sets_path(@workout), params: {
      planned_entry: {
        exercise_id: exercises(:squat).id,
        set_count: 3,
        rep_pattern: "8"
      }
    }

    assert_redirected_to new_session_path
  end
end
