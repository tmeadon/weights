class WorkoutSetsController < ApplicationController
  before_action :set_workout
  before_action :set_workout_set, only: %i[edit update destroy]
  before_action :load_exercises, only: %i[new create edit update]

  def new
    @workout_set = @workout.workout_sets.new
  end

  def create
    @workout_set = @workout.workout_sets.new(workout_set_params)

    if @workout_set.save
      redirect_to workout_path(@workout), notice: "Planned set added."
    else
      render :new, status: :unprocessable_entity
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
    redirect_to workout_path(@workout), notice: "Planned set removed.", status: :see_other
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

    def reorder_positions
      @workout.workout_sets.reload.each_with_index do |workout_set, index|
        workout_set.update_column(:position, index + 1)
      end
    end
end
