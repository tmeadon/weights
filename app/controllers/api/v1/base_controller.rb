module Api
  module V1
    class BaseController < ApplicationController
      ApiKeySession = Struct.new(:user)

      include ApiSerialization

      skip_forgery_protection

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private
        def resume_session
          Current.session ||= find_session_by_api_key || find_session_by_cookie
        end

        def serialize_user(user)
          {
            id: user.id,
            email_address: user.email_address,
            api_key: user.api_key,
            created_at: user.created_at,
            updated_at: user.updated_at
          }
        end

        def request_authentication
          render_error("Authentication required.", :unauthorized)
        end

        def find_session_by_api_key
          key = api_key_from_request
          return if key.blank?

          user = User.find_by(api_key: key)
          return if user.blank?

          ApiKeySession.new(user)
        end

        def api_key_from_request
          request.get_header("HTTP_X_API_KEY").presence || bearer_api_key
        end

        def bearer_api_key
          scheme, token = request.authorization.to_s.split(" ", 2)
          return unless scheme&.casecmp("Bearer")&.zero?

          token
        end

        def render_not_found(exception)
          render_error(exception.message, :not_found)
        end

        def render_bad_request(exception)
          render_error(exception.message, :bad_request)
        end

        def render_model_errors(record, status: :unprocessable_entity)
          render json: { error: { message: "Validation failed.", details: record.errors.full_messages } }, status:
        end

        def render_error(message, status)
          render json: { error: { message: } }, status:
        end
    end
  end
end
