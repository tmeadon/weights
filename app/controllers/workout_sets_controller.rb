class WorkoutSetsController < ApplicationController
  before_action :set_workout
  before_action :set_workout_set, only: %i[edit update destroy]
  before_action :load_exercises, only: %i[new create edit update]

  def new
    @workout_set = @workout.workout_sets.new
  end

  def create
    if execution_request?
      create_execution_set
    else
      create_planned_sets
    end
  end

  def edit
  end

  def update
    if execution_request?
      update_execution_set
    else
      if @workout_set.update(workout_set_params)
        redirect_to workout_path(@workout), notice: "Planned set updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @workout_set.destroy
    reorder_positions
    @workout.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
          turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout }),
          turbo_stream.replace("workout_difficulty_totals", partial: "workouts/difficulty_totals", locals: { workout: @workout })
        ]
      end
      format.html { redirect_to workout_path(@workout), notice: "Planned set removed.", status: :see_other }
    end
  end

  def remove_exercise
    exercise_id = params[:exercise_id]
    @workout.workout_sets.where(exercise_id:).destroy_all
    reorder_positions
    @workout.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
          turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout }),
          turbo_stream.replace("workout_difficulty_totals", partial: "workouts/difficulty_totals", locals: { workout: @workout })
        ]
      end
      format.html { redirect_to workout_path(@workout), notice: "Exercise removed from workout.", status: :see_other }
    end
  end

  def move_exercise
    moved = @workout.move_exercise_block(exercise_id: params[:exercise_id], direction: params[:direction])
    @workout.reload

    respond_to do |format|
      if moved
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
            turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout }),
            turbo_stream.replace("workout_difficulty_totals", partial: "workouts/difficulty_totals", locals: { workout: @workout })
          ]
        end
        format.html { redirect_to workout_path(@workout), notice: "Exercise order updated." }
      else
        format.turbo_stream do
          flash.now[:alert] = @workout.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }), status: :unprocessable_entity
        end
        format.html { redirect_to workout_path(@workout), alert: @workout.errors.full_messages.to_sentence }
      end
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

    def execution_params
      params.expect(execution: [ :exercise_id, :actual_weight, :actual_reps ])
    end

    def planned_entry_params
      params.require(:planned_entry).permit(:exercise_id, :set_count, :rep_pattern, :target_weight, :coach_notes)
    end

    def add_planned_sets
      @planned_entry = planned_entry_params.to_h
      @workout.append_planned_entries([ @planned_entry.symbolize_keys ])
    end

    def add_execution_set
      @execution_entry = execution_params.to_h
      @workout.append_execution_entry(@execution_entry.symbolize_keys)
    end

    def create_planned_sets
      if add_planned_sets
        @workout.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: default_planned_entry, execution_entry: default_execution_entry }),
              turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
              turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout }),
              turbo_stream.replace("workout_difficulty_totals", partial: "workouts/difficulty_totals", locals: { workout: @workout })
            ]
          end
          format.html { redirect_to workout_path(@workout), notice: "Planned sets added." }
        end
      else
        @execution_entry = default_execution_entry
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: @planned_entry, execution_entry: @execution_entry }), status: :unprocessable_entity
          end
          format.html { render "workouts/show", status: :unprocessable_entity }
        end
      end
    end

    def create_execution_set
      if add_execution_set
        @workout.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: default_planned_entry, execution_entry: default_execution_entry }),
              turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout }),
              turbo_stream.update("planned_sets_count", partial: "workouts/planned_sets_count", locals: { workout: @workout }),
              turbo_stream.replace("workout_difficulty_totals", partial: "workouts/difficulty_totals", locals: { workout: @workout })
            ]
          end
          format.html { redirect_to workout_path(@workout), notice: "Set logged." }
        end
      else
        @planned_entry = default_planned_entry
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("planned_set_planner", partial: "workouts/planned_set_planner", locals: { workout: @workout, exercises: @exercises, planned_entry: @planned_entry, execution_entry: @execution_entry }), status: :unprocessable_entity
          end
          format.html { render "workouts/show", status: :unprocessable_entity }
        end
      end
    end

    def update_execution_set
      unless @workout.status == "in_progress"
        redirect_to workout_path(@workout), alert: "Only in-progress workouts can log sets."
        return
      end

      if @workout_set.update(execution_params.except(:exercise_id))
        @workout.reload
        respond_to do |format|
          format.turbo_stream do
            head :no_content
          end
          format.html { redirect_to workout_path(@workout), notice: "Set updated." }
        end
      else
        @exercise_groups = workout_set_groups_with_current_errors
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("planned_sets_list", partial: "workouts/planned_sets_list", locals: { workout: @workout, exercise_groups: @exercise_groups }), status: :unprocessable_entity
          end
          format.html do
            @planned_entry = default_planned_entry
            @execution_entry = default_execution_entry
            render "workouts/show", status: :unprocessable_entity
          end
        end
      end
    end

    def default_planned_entry
      { "exercise_id" => "", "set_count" => "3", "rep_pattern" => "8", "target_weight" => "", "coach_notes" => "" }
    end

    def default_execution_entry
      { "exercise_id" => "", "actual_weight" => "", "actual_reps" => "" }
    end

    def execution_request?
      params[:execution].present?
    end

    def reorder_positions
      @workout.workout_sets.reload.each_with_index do |workout_set, index|
        workout_set.update_column(:position, index + 1)
      end
    end

    def workout_set_groups_with_current_errors
      @workout.workout_sets.to_a.map do |workout_set|
        workout_set.id == @workout_set.id ? @workout_set : workout_set
      end.group_by(&:exercise)
    end
end
