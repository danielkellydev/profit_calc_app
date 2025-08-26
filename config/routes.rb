Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root 'sales#new', as: :authenticated_root
  end

  root 'home#index'

  resources :sales do
    collection do
      get :weekly_sales_record
    end
  end

  resources :products do
    collection do
      get :edit_all
    end
  end

  resources :dashboard, only: [:index] do
    collection do
      get :sales_data
      get :weekly_history
      get :monthly_history
      get :overview
    end
  end

  resources :sale_types
  resources :settings
  resources :custom_periods
  resources :expense_categories
  resources :expenses

  # Xero OAuth routes
  get 'auth/xero/connect', to: 'xero#connect', as: :xero_connect
  get 'auth/xero/callback', to: 'xero#callback', as: :xero_callback
  delete 'auth/xero/disconnect', to: 'xero#disconnect', as: :xero_disconnect
  get 'xero/accounts', to: 'xero#fetch_accounts', as: :xero_accounts

  get 'home/index'
end