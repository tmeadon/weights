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
    assert_select "summary", /Add note/
    assert_select "input[value='Add']"
    assert_select ".planned-set-row", /Planned/
    assert_select "button", "Remove exercise"
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
