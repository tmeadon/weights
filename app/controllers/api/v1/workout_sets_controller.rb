module Api
  module V1
    class WorkoutSetsController < BaseController
      before_action :set_workout
      before_action :set_workout_set, only: %i[update destroy]

      def create
        if params[:execution].present?
          create_execution_set
        elsif params[:planned_entry].present?
          create_planned_sets
        else
          create_single_planned_set
        end
      end

      def update
        if params[:execution].present?
          update_execution_set
        else
          update_planned_set
        end
      end

      def destroy
        @workout_set.destroy
        reorder_positions
        @workout.reload

        render json: {
          workout: serialize_workout(@workout, include_sets: true),
          message: "Workout set removed."
        }
      end

      def remove_exercise
        @workout.workout_sets.where(exercise_id: params[:exercise_id]).destroy_all
        reorder_positions
        @workout.reload

        render json: {
          workout: serialize_workout(@workout, include_sets: true),
          message: "Exercise removed from workout."
        }
      end

      private
        def set_workout
          @workout = Current.user.workouts.active.includes(workout_sets: :exercise).find(params[:workout_id])
        end

        def set_workout_set
          @workout_set = @workout.workout_sets.find(params[:id])
        end

        def create_execution_set
          if @workout.append_execution_entry(execution_params.to_h.symbolize_keys)
            @workout.reload
            render json: {
              workout_set: serialize_workout_set(@workout.workout_sets.order(:position).last),
              workout: serialize_workout(@workout, include_sets: true),
              message: "Set logged."
            }, status: :created
          else
            render_model_errors(@workout)
          end
        end

        def create_planned_sets
          before_count = @workout.workout_sets.count

          if @workout.append_planned_entries([ planned_entry_params.to_h.symbolize_keys ])
            @workout.reload
            created_sets = @workout.workout_sets.order(:position).offset(before_count)

            render json: {
              created_count: created_sets.size,
              workout_sets: created_sets.map { |workout_set| serialize_workout_set(workout_set) },
              workout: serialize_workout(@workout, include_sets: true),
              message: "Planned sets added."
            }, status: :created
          else
            render_model_errors(@workout)
          end
        end

        def create_single_planned_set
          workout_set = @workout.workout_sets.new(workout_set_params)

          if workout_set.save
            @workout.reload
            render json: {
              workout_set: serialize_workout_set(workout_set),
              workout: serialize_workout(@workout, include_sets: true)
            }, status: :created
          else
            render_model_errors(workout_set)
          end
        end

        def update_execution_set
          unless @workout.status == "in_progress"
            render_error("Only in-progress workouts can log sets.", :unprocessable_entity)
            return
          end

          if @workout_set.update(execution_params.except(:exercise_id))
            @workout.reload
            render json: {
              workout_set: serialize_workout_set(@workout_set),
              workout: serialize_workout(@workout, include_sets: true),
              message: "Set updated."
            }
          else
            render_model_errors(@workout_set)
          end
        end

        def update_planned_set
          if @workout_set.update(workout_set_params)
            @workout.reload
            render json: {
              workout_set: serialize_workout_set(@workout_set),
              workout: serialize_workout(@workout, include_sets: true),
              message: "Planned set updated."
            }
          else
            render_model_errors(@workout_set)
          end
        end

        def workout_set_params
          params.require(:workout_set).permit(:exercise_id, :position, :target_weight, :target_reps, :coach_notes)
        end

        def execution_params
          params.require(:execution).permit(:exercise_id, :actual_weight, :actual_reps)
        end

        def planned_entry_params
          params.require(:planned_entry).permit(:exercise_id, :set_count, :rep_pattern, :target_weight, :coach_notes)
        end

        def reorder_positions
          @workout.workout_sets.reload.each_with_index do |workout_set, index|
            workout_set.update_column(:position, index + 1)
          end
        end
    end
  end
end
