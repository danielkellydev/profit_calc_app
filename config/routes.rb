Rails.application.routes.draw do
  resources :dashboard, only: [:index], controller: 'dashboard' do
    collection do
      get :weekly_history
      get :sales_record
    end
  end

  resources :custom_periods, only: [:index, :new, :create, :show]
  
  resources :products do
    collection do
      get :edit_all
    end
  end

  resources :sales, only: [:create, :edit, :update, :destroy] 

  root 'dashboard#index'
end