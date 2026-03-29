require "test_helper"

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @exercise = exercises(:bench_press)
    sign_in_as(@user)
  end

  test "index" do
    get exercises_path

    assert_response :success
    assert_select "h1", "Exercise library"
    assert_select "a", "Dumbbell Bench Press"
  end

  test "search and filter the exercise library" do
    get exercises_path, params: { query: "lat", equipment_type: "Cable" }

    assert_response :success
    assert_select "a", "Lat Pulldown"
    assert_select "a", text: "Dumbbell Bench Press", count: 0
  end

  test "index hides archived exercises by default" do
    exercises(:squat).archive!

    get exercises_path

    assert_response :success
    assert_select "a", text: "Goblet Squat", count: 0
  end

  test "index can show archived exercises" do
    exercises(:squat).archive!

    get exercises_path, params: { status: "archived" }

    assert_response :success
    assert_select "a", "Goblet Squat"
    assert_select ".status-pill", "Archived"
  end

  test "create exercise" do
    assert_difference("Exercise.count", 1) do
      post exercises_path, params: {
        exercise: {
          name: "Seated Cable Row",
          movement_category: "Pull",
          primary_muscle_group: "Back",
          equipment_type: "Cable",
          notes: "Drive elbows low."
        }
      }
    end

    assert_redirected_to exercise_path(Exercise.order(:id).last)
  end

  test "update exercise" do
    patch exercise_path(@exercise), params: {
      exercise: {
        equipment_type: "Barbell"
      }
    }

    assert_redirected_to exercise_path(@exercise)
    assert_equal "Barbell", @exercise.reload.equipment_type
  end

  test "destroy archives exercise" do
    assert_no_difference("Exercise.count") do
      delete exercise_path(@exercise)
    end

    assert_redirected_to exercises_path
    assert @exercise.reload.archived?
  end

  test "restore exercise" do
    @exercise.archive!

    patch restore_exercise_path(@exercise)

    assert_redirected_to exercise_path(@exercise)
    assert_not @exercise.reload.archived?
  end

  test "bulk import creates new exercises and skips duplicates" do
    assert_difference("Exercise.count", 1) do
      post import_exercises_path, params: {
        import: {
          text: <<~TEXT
            Split Squat | Squat | Legs | Dumbbell | Rear foot flat
            Lat Pulldown | Pull | Back | Cable | Duplicate
          TEXT
        }
      }
    end

    assert_redirected_to exercises_path
    follow_redirect!
    assert_response :success
    assert_select ".import-summary", /1 created/
    assert_select ".import-summary", /Lat Pulldown/
  end

  test "requires authentication" do
    sign_out

    get exercises_path

    assert_redirected_to new_session_path
  end
end
