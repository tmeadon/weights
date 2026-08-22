class CreateProgramsAndProgramWorkoutTypes < ActiveRecord::Migration[8.1]
  def up
    create_table :programs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: false
      t.timestamps
    end

    add_index :programs, [ :user_id, :name ], unique: true
    add_index :programs, [ :user_id, :active ]

    create_table :program_workout_types do |t|
      t.references :program, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end

    add_index :program_workout_types, [ :program_id, :key ], unique: true
    add_index :program_workout_types, :key

    add_reference :workouts, :program_workout_type, foreign_key: true
    backfill_programs_and_workout_types
  end

  def down
    remove_reference :workouts, :program_workout_type, foreign_key: true
    drop_table :program_workout_types
    drop_table :programs
  end

  private
    def backfill_programs_and_workout_types
      now = connection.quote(Time.current)

      select_all("SELECT id FROM users").each do |user|
        user_id = user.fetch("id")
        legacy_program_id = insert_program(user_id, "Push / Pull / Legs", active: false, now:)
        full_body_program_id = insert_program(user_id, "Full Body ABC", active: true, now:)

        existing_types = select_values(sql([ "SELECT DISTINCT workout_type FROM workouts WHERE user_id = ? AND workout_type IS NOT NULL AND workout_type != ''", user_id ]))
        legacy_types = (%w[push pull legs] + existing_types).uniq

        legacy_types.each_with_index do |key, index|
          type_id = insert_program_workout_type(legacy_program_id, key, key.to_s.humanize, index + 1, now:)
          execute sql([ "UPDATE workouts SET program_workout_type_id = ? WHERE user_id = ? AND workout_type = ?", type_id, user_id, key ])
        end

        [ [ "a", "A", "Full Body A" ], [ "b", "B", "Full Body B" ], [ "c", "C", "Full Body C" ] ].each_with_index do |(key, name, description), index|
          insert_program_workout_type(full_body_program_id, key, name, index + 1, description:, now:)
        end
      end
    end

    def insert_program(user_id, name, active:, now:)
      execute sql([ "INSERT INTO programs (user_id, name, active, created_at, updated_at) VALUES (?, ?, ?, #{now}, #{now})", user_id, name, active ? 1 : 0 ])
      select_value("SELECT last_insert_rowid()")
    end

    def insert_program_workout_type(program_id, key, name, sort_order, description: nil, now:)
      execute sql([ "INSERT INTO program_workout_types (program_id, key, name, description, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, #{now}, #{now})", program_id, key, name, description, sort_order ])
      select_value("SELECT last_insert_rowid()")
    end

    def sql(array)
      ActiveRecord::Base.sanitize_sql_array(array)
    end
end
