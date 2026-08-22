class ProgramWorkoutTypesController < ApplicationController
  before_action :set_program
  before_action :set_workout_type, only: %i[edit update destroy create_workout]

  def new
    @workout_type = @program.program_workout_types.new(sort_order: next_sort_order)
  end

  def create
    @workout_type = @program.program_workout_types.new(workout_type_params)

    if @workout_type.save
      redirect_to program_path(@program), notice: "Workout type created."
    else
      @program_workout_types = @program.program_workout_types.select(&:persisted?)
      @recent_workouts = []
      render "programs/show", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workout_type.update(workout_type_params)
      sync_workout_legacy_keys! if @workout_type.saved_change_to_key?
      redirect_to program_path(@program), notice: "Workout type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create_workout
    workout = Current.user.workouts.create!(
      title: @workout_type.default_workout_title,
      workout_on: Date.current,
      program_workout_type: @workout_type,
      status: "draft"
    )
    @workout_type.apply_template_to_workout!(workout)

    redirect_to workout_path(workout), notice: "Workout created from #{@workout_type.label}."
  end

  def destroy
    @workout_type.destroy!
    redirect_to program_path(@program), notice: "Workout type deleted. Workout history was preserved.", status: :see_other
  end

  private
    def set_program
      @program = Current.user.programs.find(params[:program_id])
    end

    def set_workout_type
      @workout_type = @program.program_workout_types.find(params[:id])
    end

    def workout_type_params
      params.expect(program_workout_type: [ :key, :name, :description, :sort_order ])
    end

    def sync_workout_legacy_keys!
      @workout_type.workouts.update_all(workout_type: @workout_type.key)
    end

    def next_sort_order
      @program.program_workout_types.maximum(:sort_order).to_i + 1
    end
end
