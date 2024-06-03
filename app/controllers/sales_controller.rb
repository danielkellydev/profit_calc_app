class SalesController < ApplicationController
  before_action :set_weekly_sales, only: [:index]
  
  def new
    @products = Product.all
  end
  
  def create 
    @sale = Sale.new(sale_params.except(:quantity))
    @sale_date = @sale.sale_date || Date.today
    @sale.week_of_year = @sale_date.cweek
    @sale.year = @sale_date.year 
  
    if @sale.save
      params[:sale][:quantity].each do |product_id, quantity|
        product = Product.find_by(id: product_id.to_i)
        if product && quantity.to_i > 0
          sale_item = @sale.sale_items.new(product_id: product_id.to_i, quantity: quantity, cogs: product.cogs * quantity.to_i)
          sale_item.save
        end
      end
      redirect_to dashboard_index_path
    else
      @products = Product.all
      @sales = Sale.where(week_of_year: Date.today.cweek, year: Date.today.year)
      render :index 
    end
  end
  
  def destroy
    @sale = Sale.find(params[:id])
    @sale.destroy
    redirect_to dashboard_index_path, notice: 'Sale was successfully deleted.'
  end

  def edit
    @sale = Sale.find(params[:id])
  end

  def update
    @sale = Sale.find(params[:id])
    if @sale.update(sale_params)
      redirect_to dashboard_index_path, turbo_frame: 'sales_record_frame', notice: 'Sale was successfully updated.'
    else
      render :edit, turbo_frame: 'sales_record_frame'
    end
  end

  private

  def sale_params
    params.require(:sale).permit(:sale_type, :total_received, :sale_date, sale_items_attributes: [:id, :quantity, :product_id])
  end
end