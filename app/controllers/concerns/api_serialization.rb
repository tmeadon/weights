module ApiSerialization
  private
    def serialize_exercise(exercise)
      {
        id: exercise.id,
        public_id: exercise.public_id,
        name: exercise.name,
        movement_category: exercise.movement_category,
        primary_muscle_group: exercise.primary_muscle_group,
        equipment_type: exercise.equipment_type,
        notes: exercise.notes,
        archived_at: exercise.archived_at,
        created_at: exercise.created_at,
        updated_at: exercise.updated_at
      }
    end

    def serialize_workout_set(workout_set)
      {
        id: workout_set.id,
        workout_id: workout_set.workout_id,
        exercise_id: workout_set.exercise_id,
        exercise_name: workout_set.exercise.name,
        position: workout_set.position,
        target_reps: workout_set.target_reps,
        target_weight: decimal_or_nil(workout_set.target_weight),
        coach_notes: workout_set.coach_notes,
        actual_reps: workout_set.actual_reps,
        actual_weight: decimal_or_nil(workout_set.actual_weight),
        planned_difficulty: decimal(workout_set.planned_difficulty),
        actual_difficulty: decimal(workout_set.actual_difficulty),
        difficulty: decimal(workout_set.difficulty),
        created_at: workout_set.created_at,
        updated_at: workout_set.updated_at
      }
    end

    def serialize_workout(workout, include_sets: false)
      payload = {
        id: workout.id,
        user_id: workout.user_id,
        title: workout.title,
        workout_on: workout.workout_on,
        workout_type: workout.workout_type,
        notes: workout.notes,
        status: workout.status,
        deleted_at: workout.deleted_at,
        execution_logging: workout.execution_logging?,
        planned_total_difficulty: decimal(workout.planned_total_difficulty),
        actual_total_difficulty: decimal(workout.actual_total_difficulty),
        total_difficulty: decimal(workout.total_difficulty),
        created_at: workout.created_at,
        updated_at: workout.updated_at
      }

      payload[:workout_sets] = workout.workout_sets.map { |workout_set| serialize_workout_set(workout_set) } if include_sets
      payload
    end

    def decimal(value)
      value.to_d.to_f
    end

    def decimal_or_nil(value)
      value.present? ? decimal(value) : nil
    end
end
