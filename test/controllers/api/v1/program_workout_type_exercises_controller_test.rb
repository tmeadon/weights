require "test_helper"

module Api
  module V1
    class ProgramWorkoutTypeExercisesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @program = programs(:abc_one)
        @workout_type = program_workout_types(:full_body_b_one)
      end

      test "create template exercise" do
        assert_difference("ProgramWorkoutTypeExercise.count", 1) do
          post api_v1_program_program_workout_type_program_workout_type_exercises_path(@program, @workout_type),
            params: {
              program_workout_type_exercise: {
                exercise_id: exercises(:bench_press).id,
                position: 1,
                rep_pattern: "8",
                coach_notes: "AI note"
              }
            },
            as: :json,
            headers: api_headers
        end

        assert_response :created
        assert_equal "Dumbbell Bench Press", json_response.dig("template_exercise", "exercise_name")
        assert_equal "8", json_response.dig("template_exercise", "rep_pattern")
      end

      test "update template exercise" do
        template_exercise = program_workout_type_exercises(:full_body_a_bench)
        workout_type = program_workout_types(:full_body_a_one)

        patch api_v1_program_program_workout_type_program_workout_type_exercise_path(@program, workout_type, template_exercise),
          params: { program_workout_type_exercise: { rep_pattern: "10", position: 1, exercise_id: exercises(:bench_press).id } },
          as: :json,
          headers: api_headers

        assert_response :success
        assert_equal "10", json_response.dig("template_exercise", "rep_pattern")
      end

      private
        def api_headers
          { "X-Api-Key" => @user.api_key }
        end

        def json_response
          JSON.parse(response.body)
        end
    end
  end
end
