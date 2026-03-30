class WorkoutSet < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise

  normalizes :coach_notes, with: ->(value) { value.to_s.strip.presence }

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :position, uniqueness: { scope: :workout_id }
  validates :target_reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :target_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :actual_reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :actual_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { includes(:exercise).order(:position, :created_at) }

  before_validation :assign_position, on: :create
  after_commit :refresh_workout_difficulty, on: %i[create update destroy]

  def actual_logged?
    actual_reps.present? || actual_weight.present?
  end

  def difficulty
    reps = actual_reps || target_reps
    weight = actual_weight || target_weight
    return BigDecimal("0") if reps.blank? || weight.blank?

    BigDecimal(weight.to_s) * reps
  end

  private
    def assign_position
      return if position.present? || workout.blank?

      self.position = workout.workout_sets.maximum(:position).to_i + 1
    end

    def refresh_workout_difficulty
      workout&.recalculate_total_difficulty!
    end

end
