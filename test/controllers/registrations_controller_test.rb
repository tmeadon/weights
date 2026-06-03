require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new redirects to sign in when registrations are disabled" do
    get new_registration_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_match "Account creation is currently disabled.", response.body
  end

  test "create does not create a user when registrations are disabled" do
    assert_no_difference("User.count") do
      post registrations_path, params: {
        user: {
          email_address: "new@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to new_session_path
  end
end
