class Workout < ApplicationRecord
  STATUSES = %w[draft in_progress completed].freeze

  belongs_to :user
  has_many :workout_sets, -> { ordered }, dependent: :destroy
  has_many :exercises, through: :workout_sets

  normalizes :title, with: ->(value) { value.to_s.strip.squeeze(" ") }
  normalizes :notes, with: ->(value) { value.to_s.strip.presence }

  validates :title, presence: true
  validates :workout_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :total_difficulty, numericality: { greater_than_or_equal_to: 0 }
  validate :status_transition_is_allowed, if: :will_save_change_to_status?
  validate :single_active_workout_per_user, if: :status_in_progress?

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :ordered, -> { order(workout_on: :desc, created_at: :desc) }

  def self.for_user(user)
    active.where(user:).ordered
  end

  def self.current_for(user)
    active.find_by(user:, status: "in_progress")
  end

  def discarded?
    deleted_at.present?
  end

  def discard!
    update!(deleted_at: Time.current)
  end

  def append_planned_entries(entries)
    rows = Array(entries).select do |entry|
      entry.values.any?(&:present?)
    end
    return true if rows.empty?

    pending_sets = []
    next_position = workout_sets.maximum(:position).to_i + 1

    rows.each_with_index do |entry, index|
      exercise = Exercise.active.find_by(id: entry[:exercise_id])
      unless exercise
        errors.add(:base, "Planned row #{index + 1} needs an exercise.")
        return false
      end

      reps = expand_reps(entry[:rep_pattern], entry[:set_count], index + 1)
      return false if reps.nil?

      weight = parse_weight(entry[:target_weight], index + 1)
      return false if errors.any?

      reps.each do |target_reps|
        pending_sets << workout_sets.build(
          exercise:,
          target_reps:,
          target_weight: weight,
          coach_notes: entry[:coach_notes].presence,
          position: next_position
        )
        next_position += 1
      end
    end

    valid = pending_sets.all?(&:valid?)
    unless valid
      pending_sets.each do |workout_set|
        next if workout_set.errors.empty?

        errors.add(:base, workout_set.errors.full_messages.to_sentence)
      end
      return false
    end

    pending_sets.each(&:save!)
    true
  end

  private
    def expand_reps(rep_pattern, set_count, line_number)
      pattern = rep_pattern.to_s.strip
      count = set_count.to_s.strip

      if pattern.match?(/\A\d+x\d+\z/i)
        sets, reps = pattern.downcase.split("x").map(&:to_i)
        return Array.new(sets, reps)
      end

      if pattern.include?(",")
        reps = pattern.split(",").map(&:strip)
        return reps.map(&:to_i) if reps.all? { |value| value.match?(/\A\d+\z/) }

        errors.add(:base, "Planned row #{line_number} has an invalid reps pattern.")
        return nil
      end

      unless pattern.match?(/\A\d+\z/)
        errors.add(:base, "Planned row #{line_number} needs reps.")
        return nil
      end

      return Array.new(count.to_i, pattern.to_i) if count.match?(/\A\d+\z/)
      return [ pattern.to_i ] if count.blank?

      errors.add(:base, "Planned row #{line_number} has an invalid set count.")
      nil
    end

    def parse_weight(value, line_number)
      return if value.blank?

      BigDecimal(value.to_s)
    rescue ArgumentError
      errors.add(:base, "Planned row #{line_number} has an invalid weight.")
      nil
    end

    def status_in_progress?
      status == "in_progress"
    end

    def status_transition_is_allowed
      return if new_record?
      return if status_was == status

      allowed = {
        "draft" => %w[draft in_progress],
        "in_progress" => %w[in_progress completed],
        "completed" => %w[completed]
      }

      return if allowed.fetch(status_was, [ status_was ]).include?(status)

      errors.add(:status, "cannot transition from #{status_was.humanize.downcase} to #{status.humanize.downcase}")
    end

    def single_active_workout_per_user
      scope = self.class.active.where(user:, status: "in_progress")
      scope = scope.where.not(id:) if persisted?
      return unless scope.exists?

      errors.add(:status, "allows only one in-progress workout at a time")
    end
end
