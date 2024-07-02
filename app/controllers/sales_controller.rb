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
    @sale = current_user.sales.includes(sale_items: :product).find(params[:id])
  end

  def update
    begin
      Sale.transaction do
        @sale.assign_attributes(sale_params)
        update_sale_items
        if @sale.save
          redirect_to dashboard_index_path, turbo_frame: 'sales_record_frame', notice: 'Sale was successfully updated.'
        else
          render :edit, turbo_frame: 'sales_record_frame', status: :unprocessable_entity
        end
      end
    rescue => e
      log_error(e)
      flash.now[:error] = "An error occurred while updating the sale. Please try again."
      render :edit, turbo_frame: 'sales_record_frame', status: :unprocessable_entity
    end
  end

  private

  def sale_params
    params.require(:sale).permit(:sale_type_id, :total_received, :sale_date, quantity: {}, sale_items_attributes: [:id, :product_id, :quantity])
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

  def update_sale_items
    return unless params[:sale][:quantity]
  
    existing_item_ids = @sale.sale_items.pluck(:id)
    updated_item_ids = []
  
    params[:sale][:quantity].each do |product_id, quantity|
      product = current_user.products.find_by(id: product_id.to_i)
      if product && quantity.to_i > 0
        sale_item = @sale.sale_items.find_or_initialize_by(product_id: product_id.to_i)
        sale_item.quantity = quantity.to_i
        sale_item.cogs = product.cogs * quantity.to_i
        sale_item.save!
        updated_item_ids << sale_item.id
      end
    end
  
    # Remove any sale items that weren't in the updated data
    items_to_remove = existing_item_ids - updated_item_ids
    @sale.sale_items.where(id: items_to_remove).destroy_all
  end

  def log_error(error)
    Rails.logger.error "Error with sale: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end
end