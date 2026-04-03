class Workout < ApplicationRecord
  STATUSES = %w[draft in_progress completed cancelled].freeze
  WORKOUT_TYPES = %w[push pull legs].freeze

  belongs_to :user
  has_many :workout_sets, -> { ordered }, dependent: :destroy
  has_many :exercises, through: :workout_sets

  normalizes :title, with: ->(value) { value.to_s.strip.squeeze(" ") }
  normalizes :notes, with: ->(value) { value.to_s.strip.presence }
  normalizes :workout_type, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :title, presence: true
  validates :workout_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :workout_type, inclusion: { in: WORKOUT_TYPES }, allow_nil: true
  validates :total_difficulty, numericality: { greater_than_or_equal_to: 0 }
  validates :planned_total_difficulty, numericality: { greater_than_or_equal_to: 0 }
  validate :status_transition_is_allowed, if: :will_save_change_to_status?
  validate :single_active_workout_per_user, if: :status_in_progress?

  before_update :snapshot_planned_difficulty, if: :starting_workout?

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :ordered, -> { order(workout_on: :desc, created_at: :desc) }

  def self.for_user(user)
    active.where(user:).ordered
  end

  def self.current_for(user)
    active.find_by(user:, status: "in_progress")
  end

  def workout_type_label
    workout_type&.humanize || "Unspecified"
  end

  def discarded?
    deleted_at.present?
  end

  def discard!
    update!(deleted_at: Time.current)
  end

  def planned_exercise_groups
    workout_sets.group_by(&:exercise)
  end

  def ordered_exercise_ids
    workout_sets.ordered.map(&:exercise_id).uniq
  end

  def move_exercise_block(exercise_id:, direction:)
    exercise_ids = ordered_exercise_ids
    return true if exercise_ids.size <= 1

    current_index = exercise_ids.index(exercise_id.to_i)
    unless current_index
      errors.add(:base, "Exercise is not part of this workout.")
      return false
    end

    target_index = case direction.to_s
    when "up"
      current_index - 1
    when "down"
      current_index + 1
    else
      errors.add(:base, "Direction must be up or down.")
      return false
    end

    return true if target_index.negative? || target_index >= exercise_ids.size

    exercise_ids[current_index], exercise_ids[target_index] = exercise_ids[target_index], exercise_ids[current_index]
    apply_exercise_order(exercise_ids)
    true
  end

  def summarize_planned_group(workout_sets)
    reps = workout_sets.map(&:target_reps).compact
    weight = workout_sets.map(&:target_weight).compact.uniq

    rep_summary = if reps.empty?
      "Targets pending"
    elsif reps.uniq.size == 1
      "#{reps.size} x #{reps.first}"
    else
      reps.join(",")
    end

    if weight.one?
      "#{rep_summary} @ #{weight.first.to_f % 1 == 0 ? weight.first.to_i : weight.first.to_f} kg"
    else
      rep_summary
    end
  end

  def execution_logging?
    status.in?(%w[in_progress completed])
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

  def append_execution_entry(entry)
    unless status == "in_progress"
      errors.add(:base, "Only in-progress workouts can log sets.")
      return false
    end

    exercise = Exercise.active.find_by(id: entry[:exercise_id])
    unless exercise
      errors.add(:base, "Logged set needs an exercise.")
      return false
    end

    if entry[:actual_reps].blank?
      errors.add(:base, "Logged set needs reps.")
      return false
    end

    workout_set = workout_sets.build(
      exercise:,
      actual_reps: entry[:actual_reps],
      actual_weight: entry[:actual_weight],
      position: workout_sets.maximum(:position).to_i + 1
    )

    if workout_set.valid?
      workout_set.save!
      true
    else
      workout_set.errors.full_messages.each do |message|
        errors.add(:base, message)
      end
      false
    end
  end

  def recalculate_total_difficulty!
    total = workout_sets.reduce(BigDecimal("0")) { |sum, workout_set| sum + workout_set.difficulty }
    update_column(:total_difficulty, total)
  end

  def planned_total_difficulty
    return super unless status == "draft"

    workout_sets.reduce(BigDecimal("0")) { |sum, workout_set| sum + workout_set.planned_difficulty }
  end

  def actual_total_difficulty
    workout_sets.reduce(BigDecimal("0")) { |sum, workout_set| sum + workout_set.actual_difficulty }
  end

  def recent_history_for_exercise(exercise_id, limit: 3)
    return [] if exercise_id.blank?

    recent_sets = WorkoutSet.joins(:workout)
      .includes(:workout)
      .where(exercise_id:)
      .where(workouts: { user_id:, deleted_at: nil })
      .where.not(workout_id: id)
      .where("workout_sets.actual_reps IS NOT NULL OR workout_sets.actual_weight IS NOT NULL")
      .order("workouts.workout_on DESC, workout_sets.position ASC, workout_sets.created_at ASC")
      .to_a

    recent_sets
      .group_by(&:workout)
      .first(limit)
      .map { |workout, sets| { workout:, sets: } }
  end

  def summarize_recent_logged_sets(workout_sets)
    sets = Array(workout_sets)
    return "" if sets.empty?

    logged_sets = sets.select { |workout_set| workout_set.actual_reps.present? || workout_set.actual_weight.present? }
    return "No logged sets" if logged_sets.empty?

    reps = logged_sets.map(&:actual_reps).compact
    weights = logged_sets.map(&:actual_weight).compact

    if reps.size == logged_sets.size && weights.size == logged_sets.size && reps.uniq.one? && weights.uniq.one?
      "#{logged_sets.size} x #{reps.first} x #{format_weight(weights.first)}kg"
    else
      logged_sets.map do |workout_set|
        "#{workout_set.actual_reps || "?"} x #{workout_set.actual_weight.present? ? format_weight(workout_set.actual_weight) : "?"}kg"
      end.join(", ")
    end
  end

  private
    def apply_exercise_order(exercise_ids)
      sets_by_exercise = workout_sets.ordered.group_by(&:exercise_id)
      next_position = 1

      transaction do
        workout_sets.each_with_index do |workout_set, index|
          workout_set.update_column(:position, -(index + 1))
        end

        exercise_ids.each do |ordered_exercise_id|
          Array(sets_by_exercise[ordered_exercise_id]).each do |workout_set|
            workout_set.update_column(:position, next_position)
            next_position += 1
          end
        end
      end
    end

    def format_weight(weight)
      number = weight.to_d
      number.frac.zero? ? number.to_i.to_s : format("%.1f", number)
    end

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
        "draft" => %w[draft in_progress cancelled],
        "in_progress" => %w[in_progress completed cancelled],
        "completed" => %w[completed draft],
        "cancelled" => %w[cancelled draft]
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

    def starting_workout?
      status_change_to_be_saved.in?([
        [ "draft", "in_progress" ],
        [ "draft", "cancelled" ]
      ])
    end

    def snapshot_planned_difficulty
      self.planned_total_difficulty = workout_sets.reduce(BigDecimal("0")) { |sum, workout_set| sum + workout_set.planned_difficulty }
    end
end
