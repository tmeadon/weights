class WorkoutsController < ApplicationController
  before_action :set_workout, only: %i[show edit update destroy exercise_history]
  before_action :load_exercises, only: :show

  def index
    @workouts = Current.user.workouts.active.ordered
    @active_workout = Workout.current_for(Current.user)
    @next_workout = find_next_workout(@workouts)
  end

  def show
    @planned_entry = default_planned_entry
    @execution_entry = default_execution_entry
  end

  def new
    @workout = Current.user.workouts.new(workout_on: Date.current)
  end

  def create
    @workout = Current.user.workouts.new(workout_params)

    if @workout.save
      redirect_to workout_path(@workout), notice: "Workout created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def exercise_history
    @exercise = Exercise.active.find_by(id: params[:exercise_id])
    @history_groups = @workout.recent_history_for_exercise(params[:exercise_id])

    render partial: "workouts/exercise_history", locals: {
      workout: @workout,
      exercise: @exercise,
      history_groups: @history_groups
    }
  end

  def update
    if @workout.update(workout_params)
      redirect_to workout_path(@workout), notice: "Workout updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout.discard!
    redirect_to workouts_path, notice: "Workout archived.", status: :see_other
  end

  private
    def set_workout
      @workout = Current.user.workouts.active.find(params[:id])
    end

    def workout_params
      params.require(:workout).permit(:title, :workout_on, :workout_type, :notes, :status)
    end

    def load_exercises
      @exercises = Exercise.active.ordered
    end

    def default_planned_entry
      { "exercise_id" => "", "set_count" => "3", "rep_pattern" => "8", "target_weight" => "", "coach_notes" => "" }
    end

    def default_execution_entry
      { "exercise_id" => "", "actual_weight" => "", "actual_reps" => "" }
    end

    def find_next_workout(workouts)
      workouts
        .select { |workout| workout.workout_on >= Date.current && workout.status.in?(%w[draft in_progress]) }
        .min_by { |workout| [ workout.workout_on, workout.created_at ] }
    end
end
