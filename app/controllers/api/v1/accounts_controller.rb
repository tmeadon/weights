module Api
  module V1
    class AccountsController < BaseController
      def show
        render json: { user: serialize_user(Current.user) }
      end
    end
  end
end
