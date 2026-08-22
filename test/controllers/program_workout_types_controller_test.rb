require "test_helper"

class ProgramWorkoutTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @program = programs(:abc_one)
    @workout_type = program_workout_types(:full_body_a_one)
    sign_in_as(@user)
  end

  test "new" do
    get new_program_program_workout_type_path(@program)

    assert_response :success
    assert_select "h1", "New workout type"
  end

  test "create workout type" do
    assert_difference("ProgramWorkoutType.count", 1) do
      post program_program_workout_types_path(@program), params: {
        program_workout_type: {
          key: "d",
          name: "D",
          description: "Full Body D",
          sort_order: 4
        }
      }
    end

    assert_redirected_to program_path(@program)
    assert_equal "Full Body D", ProgramWorkoutType.order(:id).last.description
  end

  test "update workout type syncs workout legacy keys" do
    workout = workouts(:draft_session)
    workout.update!(program_workout_type: @workout_type)

    patch program_program_workout_type_path(@program, @workout_type), params: {
      program_workout_type: {
        key: "alpha",
        name: "Alpha",
        description: "Full Body Alpha",
        sort_order: 1
      }
    }

    assert_redirected_to program_path(@program)
    assert_equal "alpha", @workout_type.reload.key
    assert_equal "alpha", workout.reload.workout_type
  end

  test "create workout from template" do
    assert_difference("Workout.count", 1) do
      assert_difference("WorkoutSet.count", 2) do
        post create_workout_program_program_workout_type_path(@program, @workout_type)
      end
    end

    workout = Workout.order(:id).last
    assert_redirected_to workout_path(workout)
    assert_equal @workout_type, workout.program_workout_type
    assert_equal [ exercises(:bench_press).id, exercises(:lat_pulldown).id ], workout.workout_sets.ordered.map(&:exercise_id).uniq
  end

  test "destroy workout type preserves workouts" do
    workout = workouts(:draft_session)
    workout.update!(program_workout_type: @workout_type)

    assert_difference("ProgramWorkoutType.count", -1) do
      assert_no_difference("Workout.count") do
        delete program_program_workout_type_path(@program, @workout_type)
      end
    end

    assert_redirected_to program_path(@program)
    assert_nil workout.reload.program_workout_type
    assert_equal "a", workout.workout_type
  end
end
