class ApplicationController < ActionController::Base
  include Authentication
  helper_method :registrations_enabled?, :password_resets_enabled?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    def registrations_enabled?
      Rails.configuration.x.registrations_enabled
    end

    def password_resets_enabled?
      Rails.configuration.x.password_resets_enabled
    end
end
