class NormalizeExerciseMetadataCasing < ActiveRecord::Migration[8.1]
  class ExerciseRecord < ApplicationRecord
    self.table_name = "exercises"
  end

  def up
    say_with_time "Normalizing exercise metadata casing" do
      ExerciseRecord.find_each do |exercise|
        updates = {
          movement_category: normalize_label(exercise.movement_category),
          primary_muscle_group: normalize_label(exercise.primary_muscle_group),
          equipment_type: normalize_label(exercise.equipment_type)
        }.compact

        next if updates.empty?
        next if updates.all? { |field, value| exercise.public_send(field) == value }

        exercise.update_columns(updates)
      end
    end
  end

  def down
  end

  private
    def normalize_label(value)
      cleaned = value.to_s.strip.squeeze(" ").presence
      return if cleaned.blank?

      cleaned.downcase.split.map(&:capitalize).join(" ")
    end
end
