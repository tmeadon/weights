class CreateWorkouts < ActiveRecord::Migration[8.1]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :workout_on, null: false
      t.text :notes
      t.string :status, null: false, default: "draft"
      t.decimal :total_difficulty, precision: 10, scale: 2, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :workouts, [ :user_id, :workout_on ]
    add_index :workouts, [ :user_id, :status ]
    add_index :workouts, :deleted_at
  end
end
