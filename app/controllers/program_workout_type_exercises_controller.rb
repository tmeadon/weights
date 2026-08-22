class ProgramWorkoutTypeExercisesController < ApplicationController
  before_action :set_program
  before_action :set_workout_type
  before_action :set_template_exercise, only: %i[edit update destroy]
  before_action :load_exercises, only: %i[new create edit update]

  def new
    @template_exercise = @workout_type.program_workout_type_exercises.new(position: next_position, rep_pattern: "8")
  end

  def create
    @template_exercise = @workout_type.program_workout_type_exercises.new(template_exercise_params)

    if @template_exercise.save
      redirect_to edit_program_program_workout_type_path(@program, @workout_type), notice: "Template exercise added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template_exercise.update(template_exercise_params)
      redirect_to edit_program_program_workout_type_path(@program, @workout_type), notice: "Template exercise updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template_exercise.destroy!
    redirect_to edit_program_program_workout_type_path(@program, @workout_type), notice: "Template exercise removed.", status: :see_other
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

    def load_exercises
      @exercises = Exercise.active.ordered
    end

    def template_exercise_params
      params.expect(program_workout_type_exercise: [ :exercise_id, :position, :rep_pattern, :coach_notes ])
    end

    def next_position
      @workout_type.program_workout_type_exercises.maximum(:position).to_i + 1
    end
end
