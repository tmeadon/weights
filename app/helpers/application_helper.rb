module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :alert
      "flash flash-alert"
    else
      "flash flash-notice"
    end
  end

  def workout_relative_date(date)
    workout_date = date.to_date
    difference = workout_date - Date.current

    return "Today" if difference.zero?
    return "Tomorrow" if difference == 1
    return "Yesterday" if difference == -1

    if difference.abs <= 28
      return "In #{difference.to_i} days" if difference.positive?

      return "#{difference.to_i.abs} days ago"
    end

    workout_date.to_fs(:long)
  end
end
