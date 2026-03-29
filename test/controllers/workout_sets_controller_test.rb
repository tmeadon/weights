require "test_helper"

class WorkoutSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workout = workouts(:draft_session)
    @workout_set = workout_sets(:draft_bench)
    sign_in_as(@user)
  end

  test "new" do
    get new_workout_workout_set_path(@workout)

    assert_response :success
    assert_select "h1", "Add a planned set"
  end

  test "create workout set" do
    assert_difference("WorkoutSet.count", 1) do
      post workout_workout_sets_path(@workout), params: {
        workout_set: {
          exercise_id: exercises(:squat).id,
          target_reps: 12,
          target_weight: 24,
          coach_notes: "Drive knees forward."
        }
      }
    end

    assert_redirected_to workout_path(@workout)
    assert_equal 3, @workout.workout_sets.reload.last.position
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

    get new_workout_workout_set_path(@workout)

    assert_redirected_to new_session_path
  end
end
