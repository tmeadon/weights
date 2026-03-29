module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :alert
      "flash flash-alert"
    else
      "flash flash-notice"
    end
  end
end
