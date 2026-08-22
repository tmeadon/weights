require "test_helper"

class ProgramWorkoutTypeExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @program = programs(:abc_one)
    @workout_type = program_workout_types(:full_body_b_one)
    @template_exercise = program_workout_type_exercises(:full_body_a_bench)
    sign_in_as(users(:one))
  end

  test "new" do
    get new_program_program_workout_type_program_workout_type_exercise_path(@program, @workout_type)

    assert_response :success
    assert_select "h1", "Add template exercise"
  end

  test "create template exercise" do
    assert_difference("ProgramWorkoutTypeExercise.count", 1) do
      post program_program_workout_type_program_workout_type_exercises_path(@program, @workout_type), params: {
        program_workout_type_exercise: {
          exercise_id: exercises(:bench_press).id,
          position: 1,
          rep_pattern: "8",
          coach_notes: "Controlled reps"
        }
      }
    end

    assert_redirected_to edit_program_program_workout_type_path(@program, @workout_type)
  end

  test "update template exercise" do
    patch program_program_workout_type_program_workout_type_exercise_path(@program, program_workout_types(:full_body_a_one), @template_exercise), params: {
      program_workout_type_exercise: {
        exercise_id: exercises(:bench_press).id,
        position: 1,
        rep_pattern: "10",
        coach_notes: "Updated notes"
      }
    }

    assert_redirected_to edit_program_program_workout_type_path(@program, program_workout_types(:full_body_a_one))
    assert_equal "Updated notes", @template_exercise.reload.coach_notes
  end

  test "destroy template exercise" do
    assert_difference("ProgramWorkoutTypeExercise.count", -1) do
      delete program_program_workout_type_program_workout_type_exercise_path(@program, program_workout_types(:full_body_a_one), @template_exercise)
    end

    assert_redirected_to edit_program_program_workout_type_path(@program, program_workout_types(:full_body_a_one))
  end
end
