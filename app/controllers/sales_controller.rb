class SalesController < ApplicationController
  before_action :set_sale_types, only: [:new, :create, :edit, :update]
  before_action :set_sale, only: [:edit, :update, :destroy]
  before_action :set_products, only: [:new, :create, :edit, :update]

  def index
    @sales = current_user.sales.order(created_at: :desc)
  end
  
  def new
    @sale = Sale.new
    @products = current_user.products 
    @sale_types = current_user.sale_types
  end
  
  def create 
    @sale = current_user.sales.new(sale_params)
    @sale_date = @sale.sale_date || Date.today
    @sale.week_of_year = @sale_date.cweek
    @sale.year = @sale_date.year 
  
    begin
      if @sale.save
        create_sale_items
        redirect_to dashboard_index_path, notice: 'Sale was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    rescue => e
      log_error(e)
      flash.now[:error] = "An error occurred while creating the sale. Please try again."
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @sale.destroy
    redirect_to dashboard_index_path, notice: 'Sale was successfully deleted.'
  end

  def edit
  end

  def update
    begin
      if @sale.update(sale_params)
        redirect_to dashboard_index_path, turbo_frame: 'sales_record_frame', notice: 'Sale was successfully updated.'
      else
        render :edit, turbo_frame: 'sales_record_frame', status: :unprocessable_entity
      end
    rescue => e
      log_error(e)
      flash.now[:error] = "An error occurred while updating the sale. Please try again."
      render :edit, turbo_frame: 'sales_record_frame', status: :unprocessable_entity
    end
  end

  private

  def sale_params
    params.require(:sale).permit(:sale_type_id, :total_received, :sale_date, quantity: {})
  end

  def set_sale_types
    @sale_types = current_user.sale_types.all
  end

  def set_sale
    @sale = current_user.sales.find(params[:id])
  end

  def set_products
    @products = current_user.products.all
  end

  def create_sale_items
    params[:sale][:quantity].each do |product_id, quantity|
      product = current_user.products.find_by(id: product_id.to_i)
      if product && quantity.to_i > 0
        @sale.sale_items.create!(product_id: product_id.to_i, quantity: quantity, cogs: product.cogs * quantity.to_i)
      end
    end
  end

  def log_error(error)
    Rails.logger.error "Error with sale: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end
end