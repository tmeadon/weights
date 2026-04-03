Rails.application.routes.draw do
  root "home#index"

  get "sign-up", to: "registrations#new", as: :new_registration
  resources :registrations, only: :create
  resource :account, only: :show
  resource :session
  resources :passwords, param: :token
  resources :exercises do
    collection do
      post :import
    end

    member do
      patch :restore
    end
  end
  resources :workouts do
    member do
      get :exercise_history
    end

    resources :workout_sets, except: %i[index show] do
      collection do
        patch :move_exercise
        delete :remove_exercise
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resources :registrations, only: :create
      resource :account, only: :show
      resources :passwords, only: %i[create update], param: :token

      resources :exercises, except: %i[new edit] do
        collection do
          post :import
        end

        member do
          patch :restore
        end
      end

      resources :workouts, except: %i[new edit] do
        collection do
          get :active
        end

        member do
          get :exercise_history
        end

        resources :workout_sets, except: %i[index show new edit] do
          collection do
            post :bulk_create
            patch :move_exercise
            delete :remove_exercise
          end
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
