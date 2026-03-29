class WorkoutSet < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise

  normalizes :coach_notes, with: ->(value) { value.to_s.strip.presence }

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :position, uniqueness: { scope: :workout_id }
  validates :target_reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :target_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { includes(:exercise).order(:position, :created_at) }

  before_validation :assign_position, on: :create

  private
    def assign_position
      return if position.present? || workout.blank?

      self.position = workout.workout_sets.maximum(:position).to_i + 1
    end
end
