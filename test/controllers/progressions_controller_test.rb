require "test_helper"

class ProgressionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "index shows progression sections" do
    get progressions_path

    assert_response :success
    assert_select "h1", "Progression"
    assert_select "h2", "Planned vs actual by workout"
    assert_select "h2", text: "Exercise-level progression", count: 0
    assert_select "turbo-frame#progression_panel", count: 1
    assert_select ".progression-timeframe", /Totals from/
    assert_select "select[name='workout_type']"
    assert_select "select[name='exercise_id']", count: 0
    assert_select ".progression-attainment-track", count: 1
    assert_select ".progression-chart-svg", count: 1
    assert_select "a", "Absolute"
    assert_select "a", "Delta"
    assert_select "a", "Workouts"
    assert_select "a", "Exercises"
  end

  test "index filters by workout type" do
    pull_workout = @user.workouts.create!(
      title: "Pull Session",
      workout_on: Date.new(2026, 4, 5),
      workout_type: "pull",
      status: "completed"
    )
    pull_workout.workout_sets.create!(
      exercise: exercises(:lat_pulldown),
      position: 1,
      target_reps: 10,
      target_weight: 40,
      actual_reps: 10,
      actual_weight: 42
    )

    get progressions_path, params: { tab: "workouts", workout_type: "push" }

    assert_response :success
    assert_select "td", text: "Push Session"
    assert_select "td", text: "Pull Session", count: 0
  end

  test "index shows exercise trend indicator" do
    first = @user.workouts.create!(
      title: "Bench One",
      workout_on: Date.new(2026, 4, 1),
      workout_type: "push",
      status: "completed"
    )
    first.workout_sets.create!(
      exercise: exercises(:bench_press),
      position: 1,
      actual_reps: 8,
      actual_weight: 20
    )

    second = @user.workouts.create!(
      title: "Bench Two",
      workout_on: Date.new(2026, 4, 8),
      workout_type: "push",
      status: "completed"
    )
    second.workout_sets.create!(
      exercise: exercises(:bench_press),
      position: 1,
      actual_reps: 10,
      actual_weight: 25
    )

    get progressions_path, params: { tab: "exercises", workout_type: "push" }

    assert_response :success
    assert_select "h2", "Exercise-level progression"
    assert_select ".trend-pill-up", text: /Up/
    assert_select ".progression-chart-svg", count: 0
  end

  test "index supports delta chart mode" do
    get progressions_path, params: { tab: "workouts", chart_mode: "delta" }

    assert_response :success
    assert_select ".progression-chart-legend-item", text: /Delta \(actual - planned\)/
  end

  test "exercise tab shows exercise filter" do
    get progressions_path, params: { tab: "exercises" }

    assert_response :success
    assert_select "h2", "Exercise-level progression"
    assert_select "select[name='exercise_id']"
  end

  test "requires authentication" do
    sign_out

    get progressions_path

    assert_redirected_to new_session_path
  end
end
