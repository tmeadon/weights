class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_key

  has_many :sessions, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :programs, dependent: :destroy
  has_many :program_workout_types, through: :programs

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create :create_default_programs!

  def create_default_programs!
    return if programs.exists?

    ppl = programs.create!(name: "Push / Pull / Legs")
    %w[push pull legs].each_with_index do |key, index|
      ppl.program_workout_types.create!(key:, name: key.humanize, sort_order: index + 1)
    end

    full_body = programs.create!(name: "Full Body ABC", active: true)
    [ [ "a", "A", "Full Body A" ], [ "b", "B", "Full Body B" ], [ "c", "C", "Full Body C" ] ].each_with_index do |(key, name, description), index|
      full_body.program_workout_types.create!(key:, name:, description:, sort_order: index + 1)
    end
  end
end
