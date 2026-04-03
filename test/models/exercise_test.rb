require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  test "normalizes whitespace in exercise fields" do
    exercise = Exercise.create!(
      name: "  Dumbbell   Row  ",
      movement_category: "  Pull  ",
      primary_muscle_group: "  Back  ",
      equipment_type: "  Dumbbell  ",
      notes: "  Brace and row.  "
    )

    assert_equal "Dumbbell Row", exercise.name
    assert_equal "Pull", exercise.movement_category
    assert_equal "Back", exercise.primary_muscle_group
    assert_equal "Dumbbell", exercise.equipment_type
    assert_equal "Brace and row.", exercise.notes
  end

  test "normalizes metadata casing" do
    exercise = Exercise.create!(
      name: "Kettlebell Swing",
      movement_category: "hInGe",
      primary_muscle_group: "gLuTeS",
      equipment_type: "keTTleBell"
    )

    assert_equal "Hinge", exercise.movement_category
    assert_equal "Glutes", exercise.primary_muscle_group
    assert_equal "Kettlebell", exercise.equipment_type
  end

  test "requires a unique exercise name" do
    duplicate = Exercise.new(name: exercises(:bench_press).name.upcase)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "imports exercises and skips duplicates" do
    result = Exercise.import_from_text(<<~TEXT)
      Romanian Deadlift | Hinge | Hamstrings | Barbell | Soft knees
      Lat Pulldown | Pull | Back | Cable | Duplicate existing
      Romanian Deadlift | Hinge | Hamstrings | Barbell | Duplicate in import
    TEXT

    assert_equal 1, result.created_count
    assert_equal [ "Lat Pulldown", "Romanian Deadlift" ], result.duplicate_names
    assert_empty result.invalid_rows
  end

  test "active filter excludes archived exercises by default" do
    exercises(:squat).archive!

    assert_includes Exercise.filter(status: "active"), exercises(:bench_press)
    assert_not_includes Exercise.filter(status: "active"), exercises(:squat)
    assert_includes Exercise.filter(status: "archived"), exercises(:squat)
  end
end
