Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root 'expenses#index', as: :authenticated_root
  end

  root 'home#index'

  resources :dashboard, only: [:index] do
    collection do
      post :refresh_woocommerce
    end
  end

  resources :settings, only: [:index]
  resources :custom_periods
  resources :expense_categories
  resources :expenses do
    resources :receipts, only: [:destroy]
  end

  get  'receipts/export', to: 'receipts#export', as: :receipts_export

  resource :woocommerce_config, only: [:edit, :update] do
    post :test_connection, on: :collection
  end

  get 'home/index'
end
