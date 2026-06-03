module Api
  module V1
    class PasswordsController < BaseController
      allow_unauthenticated_access
      before_action :ensure_password_resets_enabled
      before_action :set_user_by_token, only: :update
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: { message: "Try again later." } }, status: :too_many_requests }

      def create
        user = User.find_by(email_address: params[:email_address])
        PasswordsMailer.reset(user).deliver_later if user

        render json: { message: "Password reset instructions sent (if user with that email address exists)." }, status: :accepted
      end

      def update
        if @user.update(params.permit(:password, :password_confirmation))
          @user.sessions.destroy_all
          render json: { message: "Password has been reset." }
        else
          render_model_errors(@user)
        end
      end

      private
        def set_user_by_token
          @user = User.find_by_password_reset_token!(params[:token])
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          render_error("Password reset link is invalid or has expired.", :unprocessable_entity)
        end

        def ensure_password_resets_enabled
          return if password_resets_enabled?

          render_error("Password reset is currently disabled.", :not_found)
        end
    end
  end
end
