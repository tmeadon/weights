module Api
  module V1
    class ProgramWorkoutTypesController < BaseController
      before_action :set_program
      before_action :set_workout_type, only: %i[show update destroy create_workout comparable_history]

      def index
        workout_types = @program.program_workout_types.includes(program_workout_type_exercises: :exercise)
        render json: { workout_types: workout_types.map { |workout_type| serialize_program_workout_type(workout_type, include_template_exercises: true) } }
      end

      def show
        render json: { workout_type: serialize_program_workout_type(@workout_type, include_template_exercises: true) }
      end

      def create
        workout_type = @program.program_workout_types.new(workout_type_params)

        if workout_type.save
          render json: { workout_type: serialize_program_workout_type(workout_type, include_template_exercises: true) }, status: :created
        else
          render_model_errors(workout_type)
        end
      end

      def update
        if @workout_type.update(workout_type_params)
          @workout_type.workouts.update_all(workout_type: @workout_type.key) if @workout_type.saved_change_to_key?
          render json: { workout_type: serialize_program_workout_type(@workout_type, include_template_exercises: true) }
        else
          render_model_errors(@workout_type)
        end
      end

      def create_workout
        workout = Current.user.workouts.create!(
          title: workout_title,
          workout_on: workout_on,
          program_workout_type: @workout_type,
          status: "draft"
        )
        @workout_type.apply_template_to_workout!(workout)

        render json: { workout: serialize_workout(workout.reload, include_sets: true) }, status: :created
      end

      def comparable_history
        render json: {
          workout_type: serialize_program_workout_type(@workout_type, include_template_exercises: true),
          exercises: @workout_type.program_workout_type_exercises.includes(:exercise).map { |template_exercise| comparable_history_for(template_exercise) }
        }
      end

      def destroy
        @workout_type.destroy!
        render json: { message: "Workout type deleted. Workout history was preserved." }
      end

      private
        def set_program
          @program = Current.user.programs.find(params[:program_id])
        end

        def set_workout_type
          @workout_type = @program.program_workout_types.find(params[:id])
        end

        def workout_type_params
          params.require(:program_workout_type).permit(:key, :name, :description, :sort_order)
        end

        def comparable_history_for(template_exercise)
          {
            template_exercise: serialize_program_workout_type_exercise(template_exercise),
            exercise: serialize_exercise(template_exercise.exercise),
            history: {
              same_workout_type: history_groups_for(template_exercise.exercise_id, scope: :same_workout_type),
              same_program: history_groups_for(template_exercise.exercise_id, scope: :same_program),
              all_workouts: history_groups_for(template_exercise.exercise_id, scope: :all_workouts)
            }
          }
        end

        def history_groups_for(exercise_id, scope:, limit: 5)
          sets = WorkoutSet.joins(:workout)
            .includes(:exercise, workout: :program_workout_type)
            .merge(Current.user.workouts.active)
            .where(exercise_id:)
            .where("workout_sets.actual_reps IS NOT NULL OR workout_sets.actual_weight IS NOT NULL")

          sets = case scope
          when :same_workout_type
            sets.where(workouts: { program_workout_type_id: @workout_type.id })
          when :same_program
            sets.joins(workout: :program_workout_type).where(program_workout_types: { program_id: @program.id })
          else
            sets
          end

          sets
            .order("workouts.workout_on DESC, workouts.created_at DESC, workout_sets.position ASC, workout_sets.created_at ASC")
            .to_a
            .group_by(&:workout)
            .first(limit)
            .map { |workout, workout_sets| serialize_history_group(workout, workout_sets) }
        end

        def serialize_history_group(workout, workout_sets)
          {
            workout: serialize_workout(workout),
            sets: workout_sets.map { |workout_set| serialize_workout_set(workout_set) },
            summary: workout.summarize_recent_logged_sets(workout_sets),
            exercise_total_difficulty: workout_sets.sum { |workout_set| workout_set.actual_difficulty.to_d }.to_f
          }
        end

        def create_workout_params
          params.fetch(:workout, {}).permit(:title, :workout_on)
        end

        def workout_title
          create_workout_params[:title].presence || @workout_type.default_workout_title
        end

        def workout_on
          value = create_workout_params[:workout_on].presence
          value ? Date.parse(value) : Date.current
        rescue ArgumentError
          Date.current
        end
    end
  end
end
