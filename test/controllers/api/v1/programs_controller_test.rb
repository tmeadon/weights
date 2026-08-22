require "test_helper"

module Api
  module V1
    class ProgramsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @program = programs(:abc_one)
      end

      test "index requires authentication" do
        get api_v1_programs_path, as: :json

        assert_response :unauthorized
      end

      test "index returns programs with workout types and templates" do
        get api_v1_programs_path, as: :json, headers: api_headers

        assert_response :success
        program = json_response.fetch("programs").find { |entry| entry["id"] == @program.id }
        assert_equal "Full Body ABC", program.fetch("name")
        assert_equal true, program.fetch("active")
        assert program.fetch("workout_types").any? { |type| type["key"] == "a" && type.fetch("template_exercises").any? }
      end

      test "create program" do
        assert_difference("Program.count", 1) do
          post api_v1_programs_path,
            params: { program: { name: "Upper Lower", active: true } },
            as: :json,
            headers: api_headers
        end

        assert_response :created
        assert_equal "Upper Lower", json_response.dig("program", "name")
        assert_equal true, json_response.dig("program", "active")
      end

      test "activate program" do
        program = programs(:ppl_one)

        patch activate_api_v1_program_path(program), as: :json, headers: api_headers

        assert_response :success
        assert_equal true, json_response.dig("program", "active")
        assert program.reload.active?
        assert_not @program.reload.active?
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
