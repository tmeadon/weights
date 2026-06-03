require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new redirects to sign in when password resets are disabled" do
    get new_password_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_notice "Password reset is currently disabled"
  end

  test "create does not send reset instructions when password resets are disabled" do
    assert_enqueued_emails 0 do
      post passwords_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_session_path
    follow_redirect!
    assert_notice "Password reset is currently disabled"
  end

  test "edit redirects to sign in when password resets are disabled" do
    get edit_password_path(@user.password_reset_token)

    assert_redirected_to new_session_path
    follow_redirect!
    assert_notice "Password reset is currently disabled"
  end

  test "update does not change password when password resets are disabled" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "new", password_confirmation: "new" }
    end

    assert_redirected_to new_session_path
    follow_redirect!
    assert_notice "Password reset is currently disabled"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
