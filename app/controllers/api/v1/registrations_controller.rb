module Api
  module V1
    class RegistrationsController < BaseController
      allow_unauthenticated_access only: :create

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
    end
  end
end
