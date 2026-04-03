module Api
  module V1
    class ExercisesController < BaseController
      before_action :set_exercise, only: %i[show update destroy restore]

      def index
        filters = params.permit(:query, :movement_category, :primary_muscle_group, :equipment_type, :status).to_h.symbolize_keys
        exercises = Exercise.filter(filters)

        render json: {
          exercises: exercises.map { |exercise| serialize_exercise(exercise) },
          filters:,
          filter_options: {
            movement_categories: Exercise.filter_options_for(:movement_category),
            primary_muscle_groups: Exercise.filter_options_for(:primary_muscle_group),
            equipment_types: Exercise.filter_options_for(:equipment_type)
          }
        }
      end

      def show
        render json: { exercise: serialize_exercise(@exercise) }
      end

      def create
        exercise = Exercise.new(exercise_params)

        if exercise.save
          render json: { exercise: serialize_exercise(exercise) }, status: :created
        else
          render_model_errors(exercise)
        end
      end

      def update
        if @exercise.update(exercise_params)
          render json: { exercise: serialize_exercise(@exercise) }
        else
          render_model_errors(@exercise)
        end
      end

      def destroy
        @exercise.archive!
        render json: { exercise: serialize_exercise(@exercise), message: "Exercise archived." }
      end

      def restore
        @exercise.restore!
        render json: { exercise: serialize_exercise(@exercise), message: "Exercise restored." }
      end

      def import
        result = Exercise.import_from_text(import_text)

        render json: {
          import_result: {
            created_count: result.created_count,
            duplicate_names: result.duplicate_names,
            invalid_rows: result.invalid_rows
          }
        }, status: :created
      end

      private
        def set_exercise
          @exercise = Exercise.find(params[:id])
        end

        def exercise_params
          params.require(:exercise).permit(:name, :movement_category, :primary_muscle_group, :equipment_type, :notes)
        end

        def import_text
          params.dig(:import, :text) || params[:text].to_s
        end
    end
  end
end
