Rails.application.routes.draw do
  resources :dashboard, only: [:index], controller: 'dashboard' do
    collection do
      post :create_sale
      get :edit_products
      post :create_product
      get :weekly_history
      get :sales_record
    end
  end

  resources :products, only: [:edit, :update, :destroy]
  resources :sales, only: [:edit, :update, :destroy] # Add this line
end