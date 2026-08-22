class ProgramWorkoutTypeExercise < ApplicationRecord
  belongs_to :program_workout_type
  belongs_to :exercise

  normalizes :coach_notes, with: ->(value) { value.to_s.strip.presence }

  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :rep_pattern, presence: true

  scope :ordered, -> { order(:position, :id) }

  def target_reps
    rep_pattern.to_s.strip.to_i
  end
end
