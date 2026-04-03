module Api
  module V1
    class WorkoutsController < BaseController
      before_action :set_workout, only: %i[show update destroy exercise_history]

      def index
        workouts = Current.user.workouts.active.ordered.includes(workout_sets: :exercise)

        render json: {
          workouts: workouts.map { |workout| serialize_workout(workout) },
          active_workout_id: Workout.current_for(Current.user)&.id
        }
      end

      def active
        workout = Workout.current_for(Current.user)
        render json: { workout: workout ? serialize_workout(workout, include_sets: true) : nil }
      end

      def show
        render json: { workout: serialize_workout(@workout, include_sets: true) }
      end

      def create
        workout = Current.user.workouts.new(workout_params)

        if workout.save
          render json: { workout: serialize_workout(workout, include_sets: true) }, status: :created
        else
          render_model_errors(workout)
        end
      end

      def update
        if @workout.update(workout_params)
          render json: { workout: serialize_workout(@workout, include_sets: true) }
        else
          render_model_errors(@workout)
        end
      end

      def destroy
        @workout.discard!
        render json: { workout: serialize_workout(@workout), message: "Workout archived." }
      end

      def exercise_history
        exercise = Exercise.active.find_by(id: params[:exercise_id])
        history_groups = @workout.recent_history_for_exercise(params[:exercise_id])

        render json: {
          exercise: exercise ? serialize_exercise(exercise) : nil,
          history_groups: history_groups.map do |group|
            {
              workout: serialize_workout(group[:workout]),
              sets: group[:sets].map { |workout_set| serialize_workout_set(workout_set) },
              summary: @workout.summarize_recent_logged_sets(group[:sets])
            }
          end
        }
      end

      private
        def set_workout
          @workout = Current.user.workouts.active.includes(workout_sets: :exercise).find(params[:id])
        end

        def workout_params
          params.require(:workout).permit(:title, :workout_on, :workout_type, :notes, :status)
        end
    end
  end
end
