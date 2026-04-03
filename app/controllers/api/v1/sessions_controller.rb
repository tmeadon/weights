module Api
  module V1
    class SessionsController < BaseController
      allow_unauthenticated_access only: :create
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: { message: "Try again later." } }, status: :too_many_requests }

      def create
        user = User.authenticate_by(params.permit(:email_address, :password))

        if user
          start_new_session_for(user)
          render json: { user: serialize_user(user) }
        else
          render_error("Try another email address or password.", :unauthorized)
        end
      end

      def destroy
        terminate_session if Current.session
        head :no_content
      end
    end
  end
end
