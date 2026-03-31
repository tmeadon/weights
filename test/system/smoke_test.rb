require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path
    assert_text "Weights"
  end
end
