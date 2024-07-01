Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  root 'home#index'

  resources :sales, only: [:new, :create, :edit, :update, :destroy] do
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
    end
  end

  resources :sale_types

  get 'home/index'
end