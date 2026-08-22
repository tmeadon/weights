module Api
  module V1
    class ProgramWorkoutTypeExercisesController < BaseController
      before_action :set_program
      before_action :set_workout_type
      before_action :set_template_exercise, only: %i[show update destroy]

      def index
        template_exercises = @workout_type.program_workout_type_exercises.includes(:exercise)
        render json: { template_exercises: template_exercises.map { |template_exercise| serialize_program_workout_type_exercise(template_exercise) } }
      end

      def show
        render json: { template_exercise: serialize_program_workout_type_exercise(@template_exercise) }
      end

      def create
        template_exercise = @workout_type.program_workout_type_exercises.new(template_exercise_params)

        if template_exercise.save
          render json: { template_exercise: serialize_program_workout_type_exercise(template_exercise) }, status: :created
        else
          render_model_errors(template_exercise)
        end
      end

      def update
        if @template_exercise.update(template_exercise_params)
          render json: { template_exercise: serialize_program_workout_type_exercise(@template_exercise) }
        else
          render_model_errors(@template_exercise)
        end
      end

      def destroy
        @template_exercise.destroy!
        render json: { message: "Template exercise removed." }
      end

      private
        def set_program
          @program = Current.user.programs.find(params[:program_id])
        end

        def set_workout_type
          @workout_type = @program.program_workout_types.find(params[:program_workout_type_id])
        end

        def set_template_exercise
          @template_exercise = @workout_type.program_workout_type_exercises.find(params[:id])
        end

        def template_exercise_params
          params.require(:program_workout_type_exercise).permit(:exercise_id, :position, :rep_pattern, :coach_notes)
        end
    end
  end
end
