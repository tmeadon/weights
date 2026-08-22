class ProgramWorkoutType < ApplicationRecord
  belongs_to :program
  has_one :user, through: :program
  has_many :workouts, dependent: :nullify
  has_many :program_workout_type_exercises, -> { ordered }, dependent: :destroy
  has_many :template_exercises, through: :program_workout_type_exercises, source: :exercise

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

  def apply_template_to_workout!(workout)
    next_position = workout.workout_sets.maximum(:position).to_i + 1

    program_workout_type_exercises.each do |template_exercise|
      workout.workout_sets.create!(
        exercise: template_exercise.exercise,
        position: next_position,
        target_reps: template_exercise.target_reps,
        coach_notes: template_exercise.coach_notes
      )
      next_position += 1
    end
  end

  def default_workout_title
    "#{label} Workout"
  end
end
