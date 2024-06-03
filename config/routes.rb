Rails.application.routes.draw do
  resources :dashboard, only: [:index], controller: 'dashboard' do
    collection do
      get :weekly_history
      get :sales_data
    end
  end

  resources :custom_periods, only: [:index, :new, :create, :show]
  
  resources :products do
    collection do
      get :edit_all
    end
  end

  resources :sales, only: [:new, :create, :edit, :update, :destroy] do
    collection do
      get :weekly_sales_record
    end
  end

  root 'dashboard#index'
end