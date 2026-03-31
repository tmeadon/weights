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
    assert_select "h2", /set/
    assert_select "h3", /Dumbbell Bench Press/
    assert_select "summary", /Add note/
    assert_select "input[value='Add']"
    assert_select ".planned-set-row", /Planned/
    assert_select "button", "Remove exercise"
    assert_select "button", "Start workout"
    assert_select "button", "Cancel workout"
    assert_select "button", text: "Archive", count: 0
  end

  test "start workout from show" do
    workouts(:active_session).update!(status: "completed")
    patch workout_path(@workout), params: { workout: { status: "in_progress" } }

    assert_redirected_to workout_path(@workout)
    assert_equal "in_progress", @workout.reload.status
  end

  test "cancel workout from show" do
    patch workout_path(@workout), params: { workout: { status: "cancelled" } }

    assert_redirected_to workout_path(@workout)
    assert_equal "cancelled", @workout.reload.status
  end

  test "show active workout includes execution logging controls" do
    get workout_path(workouts(:active_session))

    assert_response :success
    assert_select ".panel-label", "Log extra set"
    assert_select "input[value='Log set']"
    assert_select "input[name='execution[actual_reps]']"
  end

  test "create workout" do
    assert_difference("Workout.count", 1) do
      post workouts_path, params: {
        workout: {
          title: "Push Session",
          workout_on: "2026-03-30",
          notes: "Start with bench.",
          status: "draft"
        }
      }
    end

    workout = Workout.order(:id).last
    assert_redirected_to workout_path(workout)
    assert_equal 0, workout.workout_sets.count
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

  test "edit shows archive action" do
    get edit_workout_path(@workout)

    assert_response :success
    assert_select "form button", "Archive workout"
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
