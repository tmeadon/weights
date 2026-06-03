require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index hides account creation links when registrations are disabled" do
    get root_path

    assert_response :success
    assert_select "a", text: "Create account", count: 0
    assert_select "a", text: "Sign in"
  end
end
