require "test_helper"

module Api
  module V1
    class ApiControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @draft_workout = workouts(:draft_session)
        @active_workout = workouts(:active_session)
      end

      test "session create returns authenticated user" do
        post api_v1_session_path,
          params: { email_address: @user.email_address, password: "password" },
          as: :json

        assert_response :success
        assert_equal @user.email_address, json_response.dig("user", "email_address")
        assert_equal @user.api_key, json_response.dig("user", "api_key")
      end

      test "workouts index requires authentication" do
        get api_v1_workouts_path, as: :json

        assert_response :unauthorized
        assert_equal "Authentication required.", json_response.dig("error", "message")
      end

      test "workouts index returns current user workouts" do
        sign_in_as(@user)

        get api_v1_workouts_path, as: :json

        assert_response :success
        assert_equal workouts(:active_session).id, json_response["active_workout_id"]
        assert_includes json_response.fetch("workouts").map { |workout| workout["id"] }, @draft_workout.id
      end

      test "workouts index accepts x-api-key authentication" do
        get api_v1_workouts_path,
          as: :json,
          headers: { "X-Api-Key" => @user.api_key }

        assert_response :success
        assert_includes json_response.fetch("workouts").map { |workout| workout["id"] }, @draft_workout.id
      end

      test "workouts index accepts bearer api key authentication" do
        get api_v1_workouts_path,
          as: :json,
          headers: { "Authorization" => "Bearer #{@user.api_key}" }

        assert_response :success
        assert_includes json_response.fetch("workouts").map { |workout| workout["id"] }, @draft_workout.id
      end

      test "create planned sets through api" do
        sign_in_as(@user)

        assert_difference("WorkoutSet.count", 3) do
          post api_v1_workout_workout_sets_path(@draft_workout),
            params: {
              planned_entry: {
                exercise_id: exercises(:squat).id,
                set_count: 3,
                rep_pattern: "8",
                target_weight: 28
              }
            },
            as: :json
        end

        assert_response :created
        assert_equal 3, json_response["created_count"]
      end

      test "create execution set through api" do
        sign_in_as(@user)

        assert_difference("WorkoutSet.count", 1) do
          post api_v1_workout_workout_sets_path(@active_workout),
            params: {
              execution: {
                exercise_id: exercises(:bench_press).id,
                actual_reps: 9,
                actual_weight: 30
              }
            },
            as: :json
        end

        assert_response :created
        assert_equal "Set logged.", json_response["message"]
      end

      test "bulk create planned sets through api" do
        sign_in_as(@user)

        assert_difference("WorkoutSet.count", 6) do
          post bulk_create_api_v1_workout_workout_sets_path(@draft_workout),
            params: {
              planned_entries: [
                {
                  exercise_id: exercises(:bench_press).id,
                  rep_pattern: "3x8",
                  target_weight: 30,
                  coach_notes: "Steady tempo"
                },
                {
                  exercise_id: exercises(:squat).id,
                  rep_pattern: "9,9,8",
                  target_weight: 40
                }
              ]
            },
            as: :json
        end

        assert_response :created
        assert_equal 6, json_response["created_count"]
        assert_equal "Planned sets added.", json_response["message"]
      end

      test "exercise import returns duplicate and created summary" do
        sign_in_as(@user)

        post import_api_v1_exercises_path,
          params: {
            import: {
              text: <<~TEXT
                Split Squat | Squat | Legs | Dumbbell | Rear foot flat
                Lat Pulldown | Pull | Back | Cable | Duplicate
              TEXT
            }
          },
          as: :json

        assert_response :created
        assert_equal 1, json_response.dig("import_result", "created_count")
        assert_includes json_response.dig("import_result", "duplicate_names"), "Lat Pulldown"
      end

      private
        def json_response
          JSON.parse(response.body)
        end
    end
  end
end
