require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "creates default programs for new users" do
    user = User.create!(email_address: "new@example.com", password: "password123")

    assert_equal [ "Full Body ABC", "Push / Pull / Legs" ], user.programs.order(:name).pluck(:name)
    assert_equal %w[a b c legs pull push], user.program_workout_types.pluck(:key).sort
  end
end
