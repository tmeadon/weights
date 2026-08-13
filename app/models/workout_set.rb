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
  after_commit :refresh_personal_bests, on: %i[create update]
  before_destroy :capture_previous_personal_best_exercise_id
  after_destroy_commit :refresh_personal_bests_after_destroy

  def actual_logged?
    actual_reps.present? || actual_weight.present?
  end

  def difficulty
    actual_logged? ? actual_difficulty : planned_difficulty
  end

  def planned_difficulty
    compute_difficulty(target_reps, target_weight)
  end

  def actual_difficulty
    compute_difficulty(actual_reps, actual_weight)
  end

  def personal_best_previous_set
    workout.workout_exercise_best_for(exercise_id)&.previous_row
  end

  def personal_best_previous_label
    workout.workout_exercise_best_for(exercise_id)&.previous_label
  end

  def compact_logged_summary
    return unless actual_logged?

    "#{actual_reps || "?"}x#{format_weight(actual_weight)}kg"
  end

  private
    def assign_position
      return if position.present? || workout.blank?

      self.position = workout.workout_sets.maximum(:position).to_i + 1
    end

    def refresh_workout_difficulty
      workout&.recalculate_total_difficulty!
    end

    def refresh_personal_bests
      return unless personal_best_relevant_change?

      exercise_ids = [ exercise_id ]
      exercise_ids << exercise_id_before_last_save if saved_change_to_exercise_id?

      exercise_ids.compact.uniq.each do |relevant_exercise_id|
        workout&.recalculate_personal_bests_for_exercise!(relevant_exercise_id, affected_workout_ids: [ workout_id ])
      end
    end

    def refresh_personal_bests_after_destroy
      return if @previous_personal_best_exercise_id.blank?

      workout&.recalculate_personal_bests_for_exercise!(@previous_personal_best_exercise_id, affected_workout_ids: [ @previous_personal_best_workout_id ])
    end

    def personal_best_relevant_change?
      (actual_logged? && (saved_change_to_actual_reps? || saved_change_to_actual_weight? || saved_change_to_exercise_id?)) || previous_actual_logged?
    end

    def previous_actual_logged?
      actual_reps_before_last_save.present? || actual_weight_before_last_save.present?
    end

    def capture_previous_personal_best_exercise_id
      @previous_personal_best_exercise_id = exercise_id if actual_logged?
      @previous_personal_best_workout_id = workout_id if actual_logged?
    end

    def intensity_factor(reps)
      factor = 1.35 - (0.04 * (reps.to_i - 1))
      factor = [ factor, 0.6 ].max
      factor = [ factor, 1.35 ].min
      BigDecimal(factor.to_s)
    end

    def compute_difficulty(reps, weight)
      return BigDecimal("0") if reps.blank? || weight.blank?

      BigDecimal(weight.to_s) * reps * intensity_factor(reps)
    end

    def format_weight(value)
      number = value.to_d
      number.frac.zero? ? number.to_i.to_s : format("%.1f", number)
    end

    def format_score(value)
      number = value.to_d
      number.frac.zero? ? number.to_i.to_s : format("%.1f", number)
    end
end
