class WorkoutSetsController < ApplicationController
  before_action :set_workout
  before_action :set_workout_set, only: %i[edit update destroy]
  before_action :load_exercises, only: %i[new create edit update]

  def new
    @workout_set = @workout.workout_sets.new
  end

  def create
    if add_planned_sets
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: default_planned_entry }),
            turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
            turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout })
          ]
        end
        format.html { redirect_to workout_path(@workout), notice: "Planned sets added." }
      end
    else
      @planned_entry = planned_entry_params.to_h
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: @planned_entry }), status: :unprocessable_entity
        end
        format.html { render "workouts/show", status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @workout_set.update(workout_set_params)
      redirect_to workout_path(@workout), notice: "Planned set updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_set.destroy
    reorder_positions
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
          turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout })
        ]
      end
      format.html { redirect_to workout_path(@workout), notice: "Planned set removed.", status: :see_other }
    end
  end

  def remove_exercise
    exercise_id = params[:exercise_id]
    @workout.workout_sets.where(exercise_id:).destroy_all
    reorder_positions

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
          turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout })
        ]
      end
      format.html { redirect_to workout_path(@workout), notice: "Exercise removed from workout.", status: :see_other }
    end
  end

  private
    def set_workout
      @workout = Current.user.workouts.active.find(params[:workout_id])
    end

    def set_workout_set
      @workout_set = @workout.workout_sets.find(params[:id])
    end

    def load_exercises
      @exercises = Exercise.active.ordered
    end

    def workout_set_params
      params.expect(workout_set: [ :exercise_id, :position, :target_weight, :target_reps, :coach_notes ])
    end

    def planned_entry_params
      params.require(:planned_entry).permit(:exercise_id, :set_count, :rep_pattern, :target_weight, :coach_notes)
    end

    def add_planned_sets
      @planned_entry = planned_entry_params.to_h
      @workout.append_planned_entries([ @planned_entry.symbolize_keys ])
    end

    def default_planned_entry
      { "exercise_id" => "", "set_count" => "3", "rep_pattern" => "8", "target_weight" => "", "coach_notes" => "" }
    end

    def reorder_positions
      @workout.workout_sets.reload.each_with_index do |workout_set, index|
        workout_set.update_column(:position, index + 1)
      end
    end
end
