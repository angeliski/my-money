Rails.application.routes.draw do
  resources :transactions do
    member do
      post :mark_as_paid
      delete :mark_as_paid, action: :unmark_as_paid
    end
  end

  resources :transfers, only: [ :new, :create ]

  resources :categories
  devise_for :users

  resources :users, path: "usuarios" do
    collection do
      post :validate_operation_code
    end
  end

  resources :accounts, except: [ :destroy ] do
    member do
      delete :archive
      patch :unarchive
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

   # Defines the root path route ("/")
   root "home#index"
   get "home", to: "home#index", as: :home
end
