class Exercise < ApplicationRecord
  ImportResult = Struct.new(:created_count, :duplicate_names, :invalid_rows, keyword_init: true)

  has_many :workout_sets, dependent: :restrict_with_exception
  has_many :workouts, through: :workout_sets

  has_secure_token :public_id

  normalizes :name, with: ->(value) { value.to_s.strip.squeeze(" ") }
  normalizes :movement_category, with: ->(value) { normalize_metadata_label(value) }
  normalizes :primary_muscle_group, with: ->(value) { normalize_metadata_label(value) }
  normalizes :equipment_type, with: ->(value) { normalize_metadata_label(value) }
  normalizes :notes, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :matching, ->(query) {
    if query.present?
      where(
        "name LIKE :query OR movement_category LIKE :query OR primary_muscle_group LIKE :query OR equipment_type LIKE :query",
        query: "%#{sanitize_sql_like(query.strip)}%"
      )
    end
  }
  scope :with_movement_category, ->(value) { where(movement_category: value) if value.present? }
  scope :with_primary_muscle_group, ->(value) { where(primary_muscle_group: value) if value.present? }
  scope :with_equipment_type, ->(value) { where(equipment_type: value) if value.present? }
  scope :with_status, ->(value) {
    case value
    when "archived"
      archived
    when "all"
      all
    else
      active
    end
  }

  def self.filter(params = {})
    with_status(params[:status])
      .ordered
      .matching(params[:query])
      .with_movement_category(params[:movement_category])
      .with_primary_muscle_group(params[:primary_muscle_group])
      .with_equipment_type(params[:equipment_type])
  end

  def self.import_from_text(text)
    duplicate_names = []
    invalid_rows = []
    created_count = 0
    seen_names = Set.new

    text.to_s.each_line.with_index(1) do |line, index|
      attributes = attributes_from_import_line(line)
      next if attributes.nil?

      name = attributes[:name]

      if seen_names.include?(name.downcase) || exists?([ "LOWER(name) = ?", name.downcase ])
        duplicate_names << name
        next
      end

      exercise = new(attributes)

      if exercise.save
        seen_names << name.downcase
        created_count += 1
      else
        invalid_rows << "Line #{index}: #{exercise.errors.full_messages.to_sentence}"
      end
    end

    ImportResult.new(created_count:, duplicate_names:, invalid_rows:)
  end

  def self.filter_options_for(column)
    where.not(column => nil).distinct.order(column).pluck(column)
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  def self.attributes_from_import_line(line)
    values = line.to_s.split("|").map { |value| value.strip.presence }
    return if values.compact.empty?

    {
      name: values[0],
      movement_category: values[1],
      primary_muscle_group: values[2],
      equipment_type: values[3],
      notes: values[4]
    }
  end

  def self.normalize_metadata_label(value)
    cleaned = value.to_s.strip.squeeze(" ").presence
    return if cleaned.blank?

    cleaned.downcase.split.map(&:capitalize).join(" ")
  end
  private_class_method :attributes_from_import_line
end
