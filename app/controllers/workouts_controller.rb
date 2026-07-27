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

  def export
    @submitted = params[:export].present?
    @selected_types = @submitted ? selected_workout_types : Workout::WORKOUT_TYPES
    @include_unspecified = @submitted ? export_boolean_param(:include_unspecified) : true
    @group_by_workout_type = @submitted ? export_boolean_param(:group_by_workout_type) : true
    @include_planned_values = @submitted ? export_boolean_param(:include_planned_values) : true
    @show_workout_notes = @submitted ? export_boolean_param(:show_workout_notes) : false
    @start_date = parse_export_date(:start_date)
    @end_date = parse_export_date(:end_date)
    @export_errors = []

    if @submitted && @selected_types.empty? && !@include_unspecified
      @export_errors << "Choose at least one workout type."
    end

    @workouts = export_workouts_scope
    @markdown = WorkoutExportMarkdown.new(
      workouts: @workouts,
      selected_types: @selected_types,
      include_unspecified: @include_unspecified,
      group_by_workout_type: @group_by_workout_type,
      include_planned_values: @include_planned_values,
      show_workout_notes: @show_workout_notes,
      start_date: @start_date,
      end_date: @end_date
    ).call

    if download_requested? && @export_errors.empty?
      send_data @markdown, filename: export_filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
    end
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

    def export_workouts_scope
      scope = Current.user.workouts.active.includes(workout_sets: :exercise)
      scope = scope.where(workout_on: @start_date..) if @start_date.present?
      scope = scope.where(workout_on: ..@end_date) if @end_date.present?

      workouts = scope.order(workout_on: :asc, created_at: :asc).to_a
      workouts.select do |workout|
        type = workout.workout_type.presence || "unspecified"
        (@selected_types.include?(type) || (@include_unspecified && type == "unspecified"))
      end
    end

    def selected_workout_types
      values = Array(params.dig(:export, :workout_types)).map { |value| value.to_s.strip.downcase.presence }.compact
      values & Workout::WORKOUT_TYPES
    end

    def export_boolean_param(key)
      ActiveModel::Type::Boolean.new.cast(params.dig(:export, key))
    end

    def parse_export_date(key)
      value = params.dig(:export, key).presence
      Date.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def download_requested?
      ActiveModel::Type::Boolean.new.cast(params[:download])
    end

    def export_filename
      "weights-workouts-#{Time.current.to_date}.md"
    end
end
