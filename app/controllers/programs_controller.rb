class ProgramsController < ApplicationController
  before_action :set_program, only: %i[show edit update destroy activate]

  def index
    @programs = Current.user.programs.includes(:program_workout_types).ordered
  end

  def show
    @program_workout_types = @program.program_workout_types.includes(:program_workout_type_exercises).to_a
    @workout_type = @program.program_workout_types.new(sort_order: next_sort_order)
    @recent_workouts = Current.user.workouts.active
      .includes(:program_workout_type)
      .where(program_workout_type: @program_workout_types)
      .ordered
      .limit(10)
  end

  def new
    @program = Current.user.programs.new
  end

  def create
    @program = Current.user.programs.new(program_params)

    if @program.save
      activate_program!(@program) if active_param?
      redirect_to program_path(@program), notice: "Program created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @program.update(program_params)
      activate_program!(@program) if active_param?
      redirect_to program_path(@program), notice: "Program updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def activate
    activate_program!(@program)
    redirect_to programs_path, notice: "#{@program.name} is now active."
  end

  def destroy
    @program.destroy!
    redirect_to programs_path, notice: "Program deleted. Workout history was preserved.", status: :see_other
  end

  private
    def set_program
      @program = Current.user.programs.find(params[:id])
    end

    def program_params
      params.expect(program: [ :name ])
    end

    def active_param?
      ActiveModel::Type::Boolean.new.cast(params.dig(:program, :active))
    end

    def activate_program!(program)
      Current.user.programs.update_all(active: false)
      program.update!(active: true)
    end

    def next_sort_order
      @program.program_workout_types.maximum(:sort_order).to_i + 1
    end
end
