require "test_helper"

class ProgramsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @program = programs(:abc_one)
    sign_in_as(@user)
  end

  test "index lists programs" do
    get programs_path

    assert_response :success
    assert_select "h1", "Programs"
    assert_select "a", "Full Body ABC"
    assert_select ".status-pill", "Active"
  end

  test "show manages workout types and recent workouts" do
    workouts(:draft_session).update!(program_workout_type: program_workout_types(:full_body_a_one))

    get program_path(@program)

    assert_response :success
    assert_select "h1", "Full Body ABC"
    assert_select "h2", /types/
    assert_select "form[action='#{program_program_workout_types_path(@program)}']"
    assert_select "a", "Upper Body A"
  end

  test "create program" do
    assert_difference("Program.count", 1) do
      post programs_path, params: { program: { name: "Upper Lower", active: "1" } }
    end

    program = Program.order(:id).last
    assert_redirected_to program_path(program)
    assert program.reload.active?
    assert_not @program.reload.active?
  end

  test "update program" do
    patch program_path(@program), params: { program: { name: "Full Body A/B/C" } }

    assert_redirected_to program_path(@program)
    assert_equal "Full Body A/B/C", @program.reload.name
  end

  test "activate program" do
    program = programs(:ppl_one)

    patch activate_program_path(program)

    assert_redirected_to programs_path
    assert program.reload.active?
    assert_not @program.reload.active?
  end

  test "destroy program preserves workouts" do
    workout = workouts(:draft_session)
    workout.update!(program_workout_type: program_workout_types(:full_body_a_one))

    assert_difference("Program.count", -1) do
      assert_no_difference("Workout.count") do
        delete program_path(@program)
      end
    end

    assert_redirected_to programs_path
    assert_nil workout.reload.program_workout_type
    assert_equal "a", workout.workout_type
  end
end
