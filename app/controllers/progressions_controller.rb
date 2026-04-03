class ProgressionsController < ApplicationController
  TREND_EPSILON = BigDecimal("0.5")

  def index
    @tab = normalized_tab(params[:tab])
    @chart_mode = normalized_chart_mode(params[:chart_mode])
    @exercise_chart_mode = normalized_chart_mode(params[:exercise_chart_mode])
    @workout_types = Current.user.workouts.active.where.not(workout_type: nil).distinct.order(:workout_type).pluck(:workout_type)
    @selected_workout_type = @tab == "workouts" ? normalized_workout_type(params[:workout_type]) : nil
    @selected_workout_type = nil unless @workout_types.include?(@selected_workout_type)

    @progress_workouts = progress_workouts_scope.to_a
    @difficulty_summary = build_difficulty_summary(@progress_workouts)
    @workout_chart_points = build_workout_chart_points(@progress_workouts)
    all_exercise_stats = build_exercise_stats(@progress_workouts)
    @exercise_filter_options = all_exercise_stats

    @selected_exercise_id = params[:exercise_id].presence&.to_i
    @selected_exercise = all_exercise_stats.find { |entry| entry[:exercise].id == @selected_exercise_id }&.fetch(:exercise, nil)
    @exercise_stats = if @selected_exercise_id.present?
      all_exercise_stats.select { |entry| entry[:exercise].id == @selected_exercise_id }
    else
      all_exercise_stats
    end
    @exercise_progress_rows = build_exercise_rows(@progress_workouts, @selected_exercise_id)
    @exercise_chart_points = build_exercise_chart_points(@exercise_progress_rows)
  end

  private
    def progress_workouts_scope
      scope = Current.user.workouts.active
        .where(status: "completed")
        .includes(workout_sets: :exercise)
        .order(workout_on: :desc, created_at: :desc)

      return scope unless @selected_workout_type

      scope.where(workout_type: @selected_workout_type)
    end

    def normalized_workout_type(value)
      value.to_s.strip.downcase.presence
    end

    def normalized_tab(value)
      tab = value.to_s.strip.downcase
      return "exercises" if tab == "exercises"

      "workouts"
    end

    def normalized_chart_mode(value)
      value.to_s.strip.downcase == "delta" ? "delta" : "absolute"
    end

    def build_difficulty_summary(workouts)
      session_count = workouts.size
      planned_total = workouts.sum { |workout| workout.planned_total_difficulty.to_d }
      actual_total = workouts.sum { |workout| workout.actual_total_difficulty.to_d }

      {
        sessions: session_count,
        planned_total:,
        actual_total:,
        delta_total: actual_total - planned_total,
        planned_average: session_count.zero? ? 0 : planned_total / session_count,
        actual_average: session_count.zero? ? 0 : actual_total / session_count
      }
    end

    def build_exercise_stats(workouts)
      grouped = Hash.new { |hash, key| hash[key] = [] }

      workouts.each do |workout|
        workout.workout_sets.each do |workout_set|
          grouped[workout_set.exercise] << [ workout, workout_set ]
        end
      end

      grouped.map do |exercise, entries|
        workout_count = entries.map(&:first).uniq.size
        planned_total = entries.sum { |(_workout, workout_set)| workout_set.planned_difficulty.to_d }
        actual_total = entries.sum { |(_workout, workout_set)| workout_set.actual_difficulty.to_d }
        trend = trend_for_entries(entries)

        {
          exercise:,
          sessions: workout_count,
          planned_total:,
          actual_total:,
          delta_total: actual_total - planned_total,
          trend_direction: trend[:direction],
          trend_delta: trend[:delta]
        }
      end.sort_by { |entry| [ -entry[:sessions], -entry[:actual_total], entry[:exercise].name ] }
    end

    def trend_for_entries(entries)
      workout_totals = entries
        .group_by(&:first)
        .map do |workout, workout_entries|
          total = workout_entries.sum { |(_entry_workout, workout_set)| workout_set.actual_difficulty.to_d }
          { workout:, total: }
        end
        .sort_by { |row| [ row[:workout].workout_on, row[:workout].created_at ] }

      return { direction: :neutral, delta: BigDecimal("0") } if workout_totals.size < 2

      previous = workout_totals[-2][:total]
      latest = workout_totals[-1][:total]
      delta = latest - previous

      direction = if delta > TREND_EPSILON
        :up
      elsif delta < -TREND_EPSILON
        :down
      else
        :neutral
      end

      { direction:, delta: }
    end

    def build_exercise_rows(workouts, exercise_id)
      return [] if exercise_id.blank?

      workouts.filter_map do |workout|
        sets = workout.workout_sets.select { |workout_set| workout_set.exercise_id == exercise_id }
        next if sets.empty?

        planned_total = sets.sum { |workout_set| workout_set.planned_difficulty.to_d }
        actual_total = sets.sum { |workout_set| workout_set.actual_difficulty.to_d }

        {
          workout:,
          sets:,
          planned_total:,
          actual_total:,
          delta_total: actual_total - planned_total,
          actual_summary: workout.summarize_recent_logged_sets(sets)
        }
      end
    end

    def build_workout_chart_points(workouts)
      workouts
        .sort_by { |workout| [ workout.workout_on, workout.created_at ] }
        .last(24)
        .map do |workout|
          planned = workout.planned_total_difficulty.to_d.to_f
          actual = workout.actual_total_difficulty.to_d.to_f

          {
            label: workout.workout_on.to_fs(:short),
            planned:,
            actual:,
            delta: actual - planned
          }
        end
    end

    def build_exercise_chart_points(rows)
      Array(rows)
        .sort_by { |row| [ row[:workout].workout_on, row[:workout].created_at ] }
        .last(24)
        .map do |row|
          {
            label: row[:workout].workout_on.to_fs(:short),
            planned: row[:planned_total].to_d.to_f,
            actual: row[:actual_total].to_d.to_f,
            delta: row[:delta_total].to_d.to_f
          }
        end
    end
end
