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
      best_row = workout_set.workout.workout_exercise_best_for(workout_set.exercise_id)

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
        personal_best: best_row.present?,
        personal_best_value: decimal_or_nil(best_row&.personal_best_value),
        personal_best_previous_value: decimal_or_nil(best_row&.personal_best_previous_value),
        personal_best_previous_label: best_row&.previous_label,
        created_at: workout_set.created_at,
        updated_at: workout_set.updated_at
      }
    end

    def serialize_program(program, include_workout_types: false)
      payload = {
        id: program.id,
        user_id: program.user_id,
        name: program.name,
        active: program.active,
        created_at: program.created_at,
        updated_at: program.updated_at
      }

      if include_workout_types
        payload[:workout_types] = program.program_workout_types.map { |workout_type| serialize_program_workout_type(workout_type, include_template_exercises: true) }
      end

      payload
    end

    def serialize_program_workout_type(workout_type, include_template_exercises: false)
      payload = {
        id: workout_type.id,
        program_id: workout_type.program_id,
        key: workout_type.key,
        name: workout_type.name,
        description: workout_type.description,
        label: workout_type.label,
        sort_order: workout_type.sort_order,
        created_at: workout_type.created_at,
        updated_at: workout_type.updated_at
      }

      if include_template_exercises
        payload[:template_exercises] = workout_type.program_workout_type_exercises.map { |template_exercise| serialize_program_workout_type_exercise(template_exercise) }
      end

      payload
    end

    def serialize_program_workout_type_exercise(template_exercise)
      {
        id: template_exercise.id,
        program_workout_type_id: template_exercise.program_workout_type_id,
        exercise_id: template_exercise.exercise_id,
        exercise_name: template_exercise.exercise.name,
        position: template_exercise.position,
        rep_pattern: template_exercise.rep_pattern,
        coach_notes: template_exercise.coach_notes,
        created_at: template_exercise.created_at,
        updated_at: template_exercise.updated_at
      }
    end

    def serialize_workout(workout, include_sets: false)
      payload = {
        id: workout.id,
        user_id: workout.user_id,
        title: workout.title,
        workout_on: workout.workout_on,
        workout_type: workout.workout_type,
        workout_type_label: workout.workout_type_label,
        program_workout_type_id: workout.program_workout_type_id,
        program_id: workout.program_workout_type&.program_id,
        program_name: workout.program_workout_type&.program&.name,
        notes: workout.notes,
        status: workout.status,
        deleted_at: workout.deleted_at,
        execution_logging: workout.execution_logging?,
        planned_total_difficulty: decimal(workout.planned_total_difficulty),
        actual_total_difficulty: decimal(workout.actual_total_difficulty),
        total_difficulty: decimal(workout.total_difficulty),
        personal_best_count: workout.personal_best_count,
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
