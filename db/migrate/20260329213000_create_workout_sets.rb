class CreateWorkoutSets < ActiveRecord::Migration[8.1]
  def change
    create_table :workout_sets do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :target_weight, precision: 8, scale: 2
      t.integer :target_reps
      t.text :coach_notes

      t.timestamps
    end

    add_index :workout_sets, [ :workout_id, :position ], unique: true
    add_index :workout_sets, [ :workout_id, :exercise_id ]
  end
end
