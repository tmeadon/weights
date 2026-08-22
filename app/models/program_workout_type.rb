class ProgramWorkoutType < ApplicationRecord
  belongs_to :program
  has_one :user, through: :program
  has_many :workouts, dependent: :nullify

  normalizes :key, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :name, with: ->(value) { value.to_s.strip.squeeze(" ") }
  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :key, presence: true, uniqueness: { scope: :program_id }
  validates :name, presence: true
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { joins(:program).order("programs.active DESC, programs.name ASC, program_workout_types.sort_order ASC, program_workout_types.name ASC") }

  def label
    description.presence || name
  end
end
