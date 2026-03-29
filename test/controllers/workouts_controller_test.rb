require "test_helper"

class WorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workout = workouts(:draft_session)
    sign_in_as(@user)
  end

  test "index" do
    get workouts_path

    assert_response :success
    assert_select "h1", "Workouts"
    assert_select "a", "Upper Body A"
    assert_select "a", "Lower Body Session"
  end

  test "show" do
    get workout_path(@workout)

    assert_response :success
    assert_select "h1", "Upper Body A"
    assert_select "h2", /planned set/
    assert_select "h3", /Dumbbell Bench Press/
  end

  test "create workout" do
    assert_difference("Workout.count", 1) do
      post workouts_path, params: {
        workout: {
          title: "Push Session",
          workout_on: "2026-03-30",
          notes: "Start with bench.",
          status: "draft",
          planned_entries: {
            "0" => { exercise_id: exercises(:bench_press).id, set_count: 3, rep_pattern: "8", target_weight: 30, coach_notes: "Smooth eccentric" },
            "1" => { exercise_id: exercises(:lat_pulldown).id, set_count: 2, rep_pattern: "10", target_weight: 45, coach_notes: "Pause at chest" },
            "2" => { exercise_id: "", set_count: "", rep_pattern: "", target_weight: "", coach_notes: "" },
            "3" => { exercise_id: "", set_count: "", rep_pattern: "", target_weight: "", coach_notes: "" }
          }
        }
      }
    end

    workout = Workout.order(:id).last
    assert_redirected_to workout_path(workout)
    assert_equal 5, workout.workout_sets.count
  end

  test "update workout can add another planned set row" do
    assert_difference("WorkoutSet.count", 3) do
      patch workout_path(@workout), params: {
        workout: {
          title: @workout.title,
          workout_on: @workout.workout_on,
          notes: @workout.notes,
          status: @workout.status,
          planned_entries: {
            "0" => { exercise_id: exercises(:squat).id, set_count: "", rep_pattern: "9,9,8", target_weight: 24, coach_notes: "Controlled tempo" }
          }
        }
      }
    end

    assert_redirected_to workout_path(@workout)
    assert_equal [ 9, 9, 8 ], @workout.workout_sets.reload.last(3).map(&:target_reps)
  end

  test "does not create workout when a builder row is invalid" do
    assert_no_difference("Workout.count") do
      post workouts_path, params: {
        workout: {
          title: "Push Session",
          workout_on: "2026-03-30",
          status: "draft",
          planned_entries: {
            "0" => { exercise_id: exercises(:bench_press).id, set_count: 3, rep_pattern: "", target_weight: 30, coach_notes: "Missing reps" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".flash", /needs reps/i
  end

  test "update workout" do
    patch workout_path(@workout), params: {
      workout: {
        notes: "Updated notebook entry.",
        title: "Upper Body A Revised"
      }
    }

    assert_redirected_to workout_path(@workout)
    assert_equal "Updated notebook entry.", @workout.reload.notes
    assert_equal "Upper Body A Revised", @workout.title
  end

  test "destroy archives workout" do
    assert_no_difference("Workout.count") do
      delete workout_path(@workout)
    end

    assert_redirected_to workouts_path
    assert @workout.reload.discarded?
  end

  test "does not show deleted workouts in index" do
    @workout.discard!

    get workouts_path

    assert_response :success
    assert_select "a", text: "Upper Body A", count: 0
  end

  test "limits access to current user workouts" do
    get workout_path(workouts(:completed_session))

    assert_response :not_found
  end

  test "requires authentication" do
    sign_out

    get workouts_path

    assert_redirected_to new_session_path
  end
end
