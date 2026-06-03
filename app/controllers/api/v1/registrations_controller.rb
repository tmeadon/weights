module Api
  module V1
    class RegistrationsController < BaseController
      allow_unauthenticated_access only: :create
      before_action :ensure_registrations_enabled

      def create
        user = User.new(user_params)

        if user.save
          start_new_session_for(user)
          render json: { user: serialize_user(user) }, status: :created
        else
          render_model_errors(user)
        end
      end

      private
        def user_params
          params.require(:user).permit(:email_address, :password, :password_confirmation)
        end

        def ensure_registrations_enabled
          return if registrations_enabled?

          render_error("Account creation is currently disabled.", :not_found)
        end
    end
  end
end
