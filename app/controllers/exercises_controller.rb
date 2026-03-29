class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[show edit update destroy restore]

  def index
    @filters = exercise_filter_params.to_h.symbolize_keys
    @exercises = Exercise.filter(@filters)
    load_filter_options
    @import_result = flash[:import_result]
  end

  def show
  end

  def new
    @exercise = Exercise.new
  end

  def create
    @exercise = Exercise.new(exercise_params)

    if @exercise.save
      redirect_to exercise_path(@exercise), notice: "Exercise created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercise_path(@exercise), notice: "Exercise updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exercise.archive!
    redirect_to exercises_path, notice: "Exercise archived.", status: :see_other
  end

  def restore
    @exercise.restore!
    redirect_to exercise_path(@exercise), notice: "Exercise restored."
  end

  def import
    result = Exercise.import_from_text(import_params[:text])

    flash[:import_result] = {
      "created_count" => result.created_count,
      "duplicate_names" => result.duplicate_names,
      "invalid_rows" => result.invalid_rows
    }

    redirect_to exercises_path, notice: import_notice(result)
  end

  private
    def set_exercise
      @exercise = Exercise.find(params[:id])
    end

    def exercise_params
      params.expect(exercise: [ :name, :movement_category, :primary_muscle_group, :equipment_type, :notes ])
    end

    def import_params
      params.expect(import: [ :text ])
    end

    def exercise_filter_params
      params.permit(:query, :movement_category, :primary_muscle_group, :equipment_type, :status)
    end

    def load_filter_options
      @movement_categories = Exercise.filter_options_for(:movement_category)
      @primary_muscle_groups = Exercise.filter_options_for(:primary_muscle_group)
      @equipment_types = Exercise.filter_options_for(:equipment_type)
    end

    def import_notice(result)
      parts = [ "Imported #{result.created_count} exercise#{"s" unless result.created_count == 1}." ]
      parts << "Skipped #{result.duplicate_names.size} duplicates." if result.duplicate_names.any?
      parts << "#{result.invalid_rows.size} rows need attention." if result.invalid_rows.any?
      parts.join(" ")
    end
end
