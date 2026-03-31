# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_30_113000) do
  create_table "exercises", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "equipment_type"
    t.string "movement_category"
    t.string "name", null: false
    t.text "notes"
    t.string "primary_muscle_group"
    t.string "public_id", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_exercises_on_archived_at"
    t.index ["equipment_type"], name: "index_exercises_on_equipment_type"
    t.index ["movement_category"], name: "index_exercises_on_movement_category"
    t.index ["name"], name: "index_exercises_on_name", unique: true
    t.index ["primary_muscle_group"], name: "index_exercises_on_primary_muscle_group"
    t.index ["public_id"], name: "index_exercises_on_public_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workout_sets", force: :cascade do |t|
    t.integer "actual_reps"
    t.decimal "actual_weight", precision: 8, scale: 2
    t.text "coach_notes"
    t.datetime "created_at", null: false
    t.integer "exercise_id", null: false
    t.integer "position", null: false
    t.integer "target_reps"
    t.decimal "target_weight", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.integer "workout_id", null: false
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["workout_id", "exercise_id"], name: "index_workout_sets_on_workout_id_and_exercise_id"
    t.index ["workout_id", "position"], name: "index_workout_sets_on_workout_id_and_position", unique: true
    t.index ["workout_id"], name: "index_workout_sets_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.decimal "planned_total_difficulty", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.decimal "total_difficulty", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.date "workout_on", null: false
    t.index ["deleted_at"], name: "index_workouts_on_deleted_at"
    t.index ["user_id", "status"], name: "index_workouts_on_user_id_and_status"
    t.index ["user_id", "workout_on"], name: "index_workouts_on_user_id_and_workout_on"
    t.index ["user_id"], name: "index_workouts_on_user_id"
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "workout_sets", "exercises"
  add_foreign_key "workout_sets", "workouts"
  add_foreign_key "workouts", "users"
end
