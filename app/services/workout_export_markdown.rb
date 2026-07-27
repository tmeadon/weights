class WorkoutExportMarkdown
  TYPE_LABELS = {
    "push" => "Push",
    "pull" => "Pull",
    "legs" => "Legs",
    "unspecified" => "Unspecified"
  }.freeze

  def initialize(workouts:, selected_types:, include_unspecified:, group_by_workout_type:, include_planned_values:, show_workout_notes:, start_date: nil, end_date: nil)
    @workouts = Array(workouts).sort_by { |workout| [ workout.workout_on, workout.created_at ] }
    @selected_types = Array(selected_types).map { |value| normalize_type(value) }.uniq
    @include_unspecified = include_unspecified
    @group_by_workout_type = group_by_workout_type
    @include_planned_values = include_planned_values
    @show_workout_notes = show_workout_notes
    @start_date = start_date
    @end_date = end_date
  end

  def call
    [ header, metadata, body ].compact.join("\n\n")
  end

  private
    attr_reader :workouts, :selected_types, :include_unspecified, :group_by_workout_type, :include_planned_values, :show_workout_notes, :start_date, :end_date

    def header
      "# Workout export"
    end

    def metadata
      [
        "Time frame: #{timeframe_label}",
        "Workout types: #{selected_type_labels.join(', ')}",
        "Grouped by workout type: #{group_by_workout_type ? 'Yes' : 'No'}",
        "Planned values: #{include_planned_values ? 'Yes' : 'No'}",
        "Workout notes: #{show_workout_notes ? 'Yes' : 'No'}",
        "Generated: #{Time.current.to_fs(:long)}"
      ].join("\n")
    end

    def body
      return "_No workouts matched the selected filters._" if workouts.empty?

      if group_by_workout_type
        grouped_body
      else
        ungrouped_body
      end
    end

    def grouped_body
      ordered_types = selected_types.dup
      ordered_types << "unspecified" if include_unspecified && !ordered_types.include?("unspecified")

      sections = ordered_types.filter_map do |type|
        type_workouts = workouts.select { |workout| type_for(workout) == type }
        next if type_workouts.empty?

        [ "## #{type_label(type)}", type_workouts.map { |workout| workout_section(workout) }.join("\n\n") ].join("\n\n")
      end

      sections.join("\n\n")
    end

    def ungrouped_body
      [ "## Workouts", workouts.map { |workout| workout_section(workout) }.join("\n\n") ].join("\n\n")
    end

    def workout_section(workout)
      lines = []
      lines << "### #{workout.workout_on.to_fs(:long)}"

      if show_workout_notes && workout.notes.present?
        lines << ""
        lines << "Notes:"
        lines << indent_block(workout.notes)
      end

      lines.concat(exercise_lines(workout))
      lines.join("\n")
    end

    def exercise_lines(workout)
      items = workout.planned_exercise_groups.map do |exercise, grouped_sets|
        exercise_line(exercise, grouped_sets)
      end

      items = [ "- No exercises yet." ] if items.empty?
      items
    end

    def exercise_line(exercise, grouped_sets)
      actual = actual_summary(grouped_sets)
      planned = planned_summary(grouped_sets)

      line = "- #{exercise.name}: #{actual.presence || planned}"
      line += " [planned: #{planned}]" if include_planned_values && planned.present? && actual.present?
      line
    end

    def planned_summary(grouped_sets)
      grouped_sets.first.workout.summarize_planned_group(grouped_sets)
    end

    def actual_summary(grouped_sets)
      summary = grouped_sets.first.workout.summarize_recent_logged_sets(grouped_sets)
      summary == "No logged sets" ? nil : summary
    end

    def type_for(workout)
      workout.workout_type.presence || "unspecified"
    end

    def type_label(type)
      TYPE_LABELS.fetch(type, type.to_s.humanize)
    end

    def selected_type_labels
      labels = selected_types.map { |type| type_label(type) }
      labels << "Unspecified" if include_unspecified && !selected_types.include?("unspecified")
      labels.uniq.presence || [ "None" ]
    end

    def timeframe_label
      if start_date.present? && end_date.present?
        "#{start_date.to_fs(:long)} to #{end_date.to_fs(:long)}"
      elsif start_date.present?
        "From #{start_date.to_fs(:long)}"
      elsif end_date.present?
        "Until #{end_date.to_fs(:long)}"
      else
        "All time"
      end
    end

    def indent_block(text, prefix: "> ")
      text.to_s.lines.map { |line| "#{prefix}#{line.rstrip}" }.join("\n")
    end

    def normalize_type(value)
      value.to_s.strip.downcase.presence
    end
end
