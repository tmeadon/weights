module Api
  module V1
    class ProgramsController < BaseController
      before_action :set_program, only: %i[show update destroy activate]

      def index
        programs = Current.user.programs.includes(program_workout_types: :program_workout_type_exercises).ordered
        render json: { programs: programs.map { |program| serialize_program(program, include_workout_types: true) } }
      end

      def show
        render json: { program: serialize_program(@program, include_workout_types: true) }
      end

      def create
        program = Current.user.programs.new(program_params.except(:active))

        if program.save
          activate_program!(program) if active_param?
          render json: { program: serialize_program(program.reload, include_workout_types: true) }, status: :created
        else
          render_model_errors(program)
        end
      end

      def update
        if @program.update(program_params.except(:active))
          activate_program!(@program) if active_param?
          render json: { program: serialize_program(@program.reload, include_workout_types: true) }
        else
          render_model_errors(@program)
        end
      end

      def activate
        activate_program!(@program)
        render json: { program: serialize_program(@program.reload, include_workout_types: true) }
      end

      def destroy
        @program.destroy!
        render json: { message: "Program deleted. Workout history was preserved." }
      end

      private
        def set_program
          @program = Current.user.programs.find(params[:id])
        end

        def program_params
          params.require(:program).permit(:name, :active)
        end

        def active_param?
          ActiveModel::Type::Boolean.new.cast(program_params[:active])
        end

        def activate_program!(program)
          Current.user.programs.update_all(active: false)
          program.update!(active: true)
        end
    end
  end
end
