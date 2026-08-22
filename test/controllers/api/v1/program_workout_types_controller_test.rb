require "test_helper"

module Api
  module V1
    class ProgramWorkoutTypesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @program = programs(:abc_one)
        @workout_type = program_workout_types(:full_body_a_one)
      end

      test "create workout type" do
        assert_difference("ProgramWorkoutType.count", 1) do
          post api_v1_program_program_workout_types_path(@program),
            params: { program_workout_type: { key: "d", name: "D", description: "Full Body D", sort_order: 4 } },
            as: :json,
            headers: api_headers
        end

        assert_response :created
        assert_equal "d", json_response.dig("workout_type", "key")
      end

      test "update workout type" do
        patch api_v1_program_program_workout_type_path(@program, @workout_type),
          params: { program_workout_type: { key: "alpha", name: "Alpha", description: "Full Body Alpha", sort_order: 1 } },
          as: :json,
          headers: api_headers

        assert_response :success
        assert_equal "alpha", json_response.dig("workout_type", "key")
        assert_equal "alpha", @workout_type.reload.key
      end

      test "comparable history returns same type same program and all workout scopes" do
        get comparable_history_api_v1_program_program_workout_type_path(@program, @workout_type),
          as: :json,
          headers: api_headers

        assert_response :success
        bench = json_response.fetch("exercises").find { |entry| entry.dig("exercise", "id") == exercises(:bench_press).id }
        assert_equal [], bench.dig("history", "same_workout_type")
        assert_equal [], bench.dig("history", "same_program")
        assert bench.dig("history", "all_workouts").any? { |entry| entry.dig("workout", "workout_type") == "push" }
      end

      test "create workout from template" do
        assert_difference("Workout.count", 1) do
          assert_difference("WorkoutSet.count", 2) do
            post create_workout_api_v1_program_program_workout_type_path(@program, @workout_type),
              params: { workout: { title: "AI planned A", workout_on: "2026-04-20" } },
              as: :json,
              headers: api_headers
          end
        end

        assert_response :created
        assert_equal "AI planned A", json_response.dig("workout", "title")
        assert_equal 2, json_response.dig("workout", "workout_sets").size
        assert_equal 8, json_response.dig("workout", "workout_sets", 0, "target_reps")
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
