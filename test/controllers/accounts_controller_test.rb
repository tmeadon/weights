require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "show account" do
    get account_path

    assert_response :success
    assert_select "h1", "Me"
    assert_select "dd", @user.email_address
    assert_select "code", @user.api_key
    assert_select "p", /X-Api-Key/
    assert_select "button", "Sign out"
  end

  test "requires authentication" do
    sign_out

    get account_path

    assert_redirected_to new_session_path
  end
end
