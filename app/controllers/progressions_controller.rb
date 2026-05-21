class ProgressionsController < ApplicationController
  def index
    @tab = normalized_tab(params[:tab])
    @chart_mode = normalized_chart_mode(params[:chart_mode])
    @exercise_chart_mode = normalized_chart_mode(params[:exercise_chart_mode])
    @workout_types = Current.user.workouts.active.where.not(workout_type: nil).distinct.order(:workout_type).pluck(:workout_type)
    @selected_workout_type = @tab == "workouts" ? normalized_workout_type(params[:workout_type]) : nil
    @selected_workout_type = nil unless @workout_types.include?(@selected_workout_type)

    @progress_workouts = progress_workouts_scope.to_a.sort_by { |workout| [ workout.workout_on, workout.created_at ] }
    @workout_progress_rows = build_workout_progress_rows(@progress_workouts)
    @difficulty_summary = build_difficulty_summary(@workout_progress_rows)
    @workout_chart_points = build_workout_chart_points(@workout_progress_rows)
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
      value.to_s.strip.downcase == "relative" ? "relative" : "absolute"
    end

    def build_difficulty_summary(rows)
      session_count = rows.size
      absolute_total = rows.sum { |row| row[:absolute_total].to_d }
      latest_row = rows.last
      recent_relative = rows.last(4).filter_map { |row| row[:relative_percent]&.to_d }
      positive_relative_sessions = rows.count { |row| row[:relative_percent].to_d.positive? }
      comparable_sessions = rows.count { |row| row[:relative_percent].present? }

      {
        sessions: session_count,
        absolute_total:,
        absolute_average: session_count.zero? ? 0 : absolute_total / session_count,
        latest_absolute: latest_row&.dig(:absolute_total),
        latest_relative: latest_row&.dig(:relative_percent),
        rolling_relative_average: recent_relative.any? ? recent_relative.sum / recent_relative.size : nil,
        positive_relative_rate: comparable_sessions.zero? ? nil : (BigDecimal(positive_relative_sessions.to_s) / comparable_sessions) * 100
      }
    end

    def build_workout_progress_rows(workouts)
      previous_absolute = nil

      workouts.map do |workout|
        absolute_total = workout.actual_total_difficulty.to_d
        relative_percent = percent_change_for(absolute_total, previous_absolute)

        row = {
          workout:,
          absolute_total:,
          relative_percent:
        }

        previous_absolute = absolute_total
        row
      end
    end

    def build_exercise_stats(workouts)
      grouped = Hash.new { |hash, key| hash[key] = [] }

      workouts.each do |workout|
        workout.workout_sets.each do |workout_set|
          grouped[workout_set.exercise] << [ workout, workout_set ]
        end
      end

      grouped.map do |exercise, entries|
        workout_totals = entries
          .group_by(&:first)
          .map do |workout, workout_entries|
            total = workout_entries.sum { |(_entry_workout, workout_set)| workout_set.actual_difficulty.to_d }
            { workout:, total: }
          end
          .sort_by { |row| [ row[:workout].workout_on, row[:workout].created_at ] }

        latest_total = workout_totals.last&.dig(:total)
        previous_total = workout_totals[-2]&.dig(:total)
        latest_relative = percent_change_for(latest_total, previous_total)
        comparable_totals = workout_totals.each_cons(2).map { |previous, current| percent_change_for(current[:total], previous[:total]) }.compact

        {
          exercise:,
          sessions: workout_totals.size,
          absolute_total: workout_totals.sum { |row| row[:total] },
          latest_absolute: latest_total,
          latest_relative: latest_relative,
          average_relative: comparable_totals.any? ? comparable_totals.sum / comparable_totals.size : nil
        }
      end.sort_by { |entry| [ -entry[:sessions], -entry[:latest_absolute].to_d, entry[:exercise].name ] }
    end

    def build_exercise_rows(workouts, exercise_id)
      return [] if exercise_id.blank?

      rows = workouts.filter_map do |workout|
        sets = workout.workout_sets.select { |workout_set| workout_set.exercise_id == exercise_id }
        next if sets.empty?

        planned_total = sets.sum { |workout_set| workout_set.planned_difficulty.to_d }
        actual_total = sets.sum { |workout_set| workout_set.actual_difficulty.to_d }

        {
          workout:,
          sets:,
          planned_total:,
          actual_total:,
          actual_summary: workout.summarize_recent_logged_sets(sets)
        }
      end

      sorted_rows = rows.sort_by { |row| [ row[:workout].workout_on, row[:workout].created_at ] }

      sorted_rows.each_with_index.map do |row, index|
        previous_total = index.zero? ? nil : sorted_rows[index - 1][:actual_total]

        row.merge(relative_percent: percent_change_for(row[:actual_total], previous_total))
      end
    end

    def build_workout_chart_points(rows)
      rows.last(24).map do |row|
        {
          label: row[:workout].workout_on.to_fs(:short),
          absolute: row[:absolute_total].to_d.to_f,
          relative: row[:relative_percent]&.to_d&.to_f
        }
      end
    end

    def build_exercise_chart_points(rows)
      Array(rows).last(24).map do |row|
        {
          label: row[:workout].workout_on.to_fs(:short),
          absolute: row[:actual_total].to_d.to_f,
          relative: row[:relative_percent]&.to_d&.to_f
        }
      end
    end

    def percent_change_for(current_value, previous_value)
      return nil if current_value.nil? || previous_value.nil?

      previous = previous_value.to_d
      return nil if previous.zero?

      ((current_value.to_d - previous) / previous) * 100
    end
end
