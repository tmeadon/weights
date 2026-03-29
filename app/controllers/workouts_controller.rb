class WorkoutsController < ApplicationController
  before_action :set_workout, only: %i[show edit update destroy]
  before_action :load_exercises, only: %i[new create edit update]

  def index
    @workouts = Current.user.workouts.active.ordered
    @active_workout = Workout.current_for(Current.user)
  end

  def show
  end

  def new
    @workout = Current.user.workouts.new(workout_on: Date.current)
    @planned_entries = default_planned_entries
  end

  def create
    @workout = Current.user.workouts.new(workout_params)
    @planned_entries = planned_entries_params

    if persist_workout
      redirect_to workout_path(@workout), notice: "Workout created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @planned_entries = default_planned_entries
  end

  def update
    @workout.assign_attributes(workout_params)
    @planned_entries = planned_entries_params

    if persist_workout
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
      params.require(:workout).permit(:title, :workout_on, :notes, :status)
    end

    def load_exercises
      @exercises = Exercise.active.ordered
    end

    def planned_entries_params
      rows = params.fetch(:workout, {}).permit(planned_entries: [ :exercise_id, :set_count, :rep_pattern, :target_weight, :coach_notes ])[:planned_entries]
      return default_planned_entries if rows.blank?

      rows.values.map(&:to_h)
    end

    def default_planned_entries
      Array.new(4) { { "exercise_id" => "", "set_count" => "", "rep_pattern" => "", "target_weight" => "", "coach_notes" => "" } }
    end

    def persist_workout
      success = false

      Workout.transaction do
        success = @workout.save && @workout.append_planned_entries(@planned_entries.map(&:symbolize_keys))
        raise ActiveRecord::Rollback unless success
      end

      success
    end
end
