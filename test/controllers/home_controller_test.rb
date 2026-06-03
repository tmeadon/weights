require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index hides disabled authentication links" do
    get root_path

    assert_response :success
    assert_select "a", text: "Create account", count: 0
    assert_select "a", text: "Forgot password?", count: 0
    assert_select "a", text: "Sign in"
  end
end
