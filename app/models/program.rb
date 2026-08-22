class Program < ApplicationRecord
  belongs_to :user
  has_many :program_workout_types, -> { ordered }, dependent: :destroy

  normalizes :name, with: ->(value) { value.to_s.strip.squeeze(" ") }

  validates :name, presence: true

  scope :ordered, -> { order(active: :desc, name: :asc, created_at: :asc) }
end
