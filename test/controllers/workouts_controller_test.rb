require "test_helper"

class WorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workout = workouts(:draft_session)
    sign_in_as(@user)
  end

  test "index" do
    soon_workout = @user.workouts.create!(title: "Soon Session", workout_on: Date.current + 2, status: "draft")
    later_workout = @user.workouts.create!(title: "Later Session", workout_on: Date.current + 6, status: "draft")

    get workouts_path

    assert_response :success
    assert_select "h1", "Workouts"
    assert_select "h3 a", /Upper Body A/
    assert_select "h2 a", /Lower Body Session/
    assert_select "h3 a", /#{soon_workout.title}/
    assert_select "h3 a", /#{later_workout.title}/
    assert_select ".workout-next-pill", text: "Next up", count: 1
    assert_select "article.workout-row-next h3", /#{soon_workout.title}/
    assert_select "a", "Me"
    assert_select ".workout-row-date", /days ago|Today|Tomorrow|Yesterday|March/
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
    assert_select "button", text: "↑"
    assert_select "button", text: "↓"
    assert_select "button", "Remove exercise"
    assert_select "button", text: "Fill down", count: 0
    assert_select "button", "Start workout"
    assert_select "button", "Cancel"
    assert_select "button", text: "Archive", count: 0
  end

  test "show renders workout and coach notes as markdown" do
    @workout.update!(notes: "Hello _hello_ - **Layla**\n\n1. Hehe\n2. Togo")
    workout_sets(:draft_bench).update!(coach_notes: "**Brace** and [control](https://example.com).")

    get workout_path(@workout)

    assert_response :success
    assert_select ".workout-summary-notes em", "hello"
    assert_select ".workout-summary-notes strong", "Layla"
    assert_select ".workout-summary-notes ol li", text: "Hehe"
    assert_select ".workout-summary-notes ol li", text: "Togo"
    assert_select ".workout-note-markdown strong", "Brace"
    assert_select ".workout-note-markdown a[href='https://example.com']", "control"
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
    workouts(:active_session).workout_sets.create!(
      exercise: exercises(:squat),
      position: 2,
      target_reps: 8,
      target_weight: 32
    )

    get workout_path(workouts(:active_session))

    assert_response :success
    assert_select ".panel-label", "Add exercise or set"
    assert_select "input[value='Add']"
    assert_select "input[name='execution[actual_reps]']"
    assert_select "button", "Fill down"
    assert_select "button[data-autosave-target='status']", count: Workout.find(workouts(:active_session).id).workout_sets.count
  end

  test "show includes recent history panels for exercise selection" do
    get workout_path(@workout)

    assert_response :success
    assert_select "[data-controller='exercise-history']", count: 1
    assert_select ".exercise-history-empty", text: /Pick an exercise to see recent logged sets/
  end

  test "exercise history returns recent logged sets for the current user" do
    get exercise_history_workout_path(@workout), params: { exercise_id: exercises(:bench_press).id }

    assert_response :success
    assert_select ".panel-label", "Recent history"
    assert_select ".exercise-history-entry", count: 2
    assert_match workouts(:completed_bench_session).workout_on.to_fs(:short), response.body
    assert_match workouts(:completed_bench_session_two).workout_on.to_fs(:short), response.body
    assert_match "9 x 28kg, 10 x 26kg", response.body
    assert_match "3 x 8 x 24kg", response.body
    assert_match workouts(:completed_bench_session).workout_on.to_fs(:short), response.body
    assert_includes response.body, "exercise-history-reuse"
  end

  test "exercise history shows empty state when there is no logged history" do
    get exercise_history_workout_path(@workout), params: { exercise_id: exercises(:lat_pulldown).id }

    assert_response :success
    assert_match "No logged history for Lat Pulldown yet.", response.body
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
