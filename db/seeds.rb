exercises = [
  {
    name: "Barbell Back Squat",
    movement_category: "Squat",
    primary_muscle_group: "Legs",
    equipment_type: "Barbell",
    notes: "Brace before each rep and keep a steady descent."
  },
  {
    name: "Romanian Deadlift",
    movement_category: "Hinge",
    primary_muscle_group: "Hamstrings",
    equipment_type: "Barbell",
    notes: "Push the hips back and keep the bar close."
  },
  {
    name: "Dumbbell Bench Press",
    movement_category: "Press",
    primary_muscle_group: "Chest",
    equipment_type: "Dumbbell",
    notes: "Use a controlled eccentric and smooth lockout."
  },
  {
    name: "Standing Overhead Press",
    movement_category: "Press",
    primary_muscle_group: "Shoulders",
    equipment_type: "Barbell",
    notes: "Keep ribs down and press in a straight line."
  },
  {
    name: "Lat Pulldown",
    movement_category: "Pull",
    primary_muscle_group: "Back",
    equipment_type: "Cable",
    notes: "Pause briefly at the chest."
  },
  {
    name: "Seated Cable Row",
    movement_category: "Pull",
    primary_muscle_group: "Back",
    equipment_type: "Cable",
    notes: "Drive elbows back without shrugging."
  },
  {
    name: "Bulgarian Split Squat",
    movement_category: "Squat",
    primary_muscle_group: "Legs",
    equipment_type: "Dumbbell",
    notes: "Keep the front foot planted and torso tall."
  },
  {
    name: "Leg Curl",
    movement_category: "Curl",
    primary_muscle_group: "Hamstrings",
    equipment_type: "Machine",
    notes: "Squeeze at peak contraction."
  },
  {
    name: "Barbell Curl",
    movement_category: "Curl",
    primary_muscle_group: "Biceps",
    equipment_type: "Barbell",
    notes: "Avoid swinging through the midpoint."
  },
  {
    name: "Cable Triceps Pressdown",
    movement_category: "Extension",
    primary_muscle_group: "Triceps",
    equipment_type: "Cable",
    notes: "Keep elbows pinned and finish fully."
  }
]

exercises.each do |attributes|
  exercise = Exercise.find_or_initialize_by(name: attributes[:name])
  exercise.assign_attributes(attributes)
  exercise.archived_at = nil
  exercise.save!
end
#   end
