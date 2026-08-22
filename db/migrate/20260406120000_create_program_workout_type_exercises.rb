class CreateProgramWorkoutTypeExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :program_workout_type_exercises do |t|
      t.references :program_workout_type, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :rep_pattern, null: false
      t.text :coach_notes
      t.timestamps
    end

    add_index :program_workout_type_exercises, [ :program_workout_type_id, :position ], unique: true, name: "index_template_exercises_on_type_and_position"
  end
end
