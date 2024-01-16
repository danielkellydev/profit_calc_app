class DashboardController < ApplicationController
  before_action :set_weekly_data, only: [:index, :create_sale, :weekly_history]

  def index
    set_weekly_data
    get_specific_revenue
    @products = Product.all
    @sales = Sale.where(week_of_year: Date.today.cweek)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(:products).sum(:cogs)
    @profit = @total_revenue - @cogs 
    @nuanced_data = @sales.group(:sale_type).sum(:total_received)
    @weekly_history = @sales
  end

  def create_sale 
    @sale = Sale.new(sale_params.except(:quantity))
    @sale.week_of_year = Date.today.cweek
    @sale.year = Date.today.year 
  
    if @sale.save
      params[:sale][:quantity].each do |product_id, quantity|
        product = Product.find_by(id: product_id.to_i)
        if product && quantity.to_i > 0
          sale_item = @sale.sale_items.new(product_id: product_id.to_i, quantity: quantity)
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

  def edit_products
    @product = Product.new 
    @products = Product.all
  end

  def create_product
    @product = Product.new(product_params)
    if @product.save
      redirect_to edit_products_dashboard_path
    else
      render :edit_products
    end
  end

  def get_specific_revenue
    @new_face_to_face_revenue = Sale.where(sale_type: 'new face to face').sum(:total_received)
    @return_face_to_face_revenue = Sale.where(sale_type: 'return face to face').sum(:total_received)
    @online_revenue = Sale.where(sale_type: 'online').sum(:total_received)
  end

  def weekly_history
    @weekly_history = Sale.group(:week_of_year, :year).select('week_of_year, year, SUM(total_received) as total_revenue').map do |sale|
      cogs = SaleItem.joins(:product, :sale).where(sales: { week_of_year: sale.week_of_year, year: sale.year }).sum('sale_items.quantity * products.cogs')
      profit = sale.total_revenue - cogs
      start_date = Date.commercial(sale.year.to_i, sale.week_of_year.to_i, 1)  # Monday of the week
      end_date = Date.commercial(sale.year.to_i, sale.week_of_year.to_i, 7)  # Sunday of the week
      { week_of_year: sale.week_of_year, year: sale.year, start_date: start_date, end_date: end_date, total_revenue: sale.total_revenue, cogs: cogs, profit: profit }
    end
  end

  private

  def set_weekly_data
    @total_revenue = Sale.where(week_of_year: Date.today.cweek).sum(:total_received)
    @cogs = SaleItem.joins(:product, :sale).where(sales: { week_of_year: Date.today.cweek }).sum('sale_items.quantity * cogs')
    @profit = @total_revenue - @cogs
  end

  def sale_params
    params.require(:sale).permit(:total_received, :sale_type, quantity: params[:sale][:quantity].keys)
  end

  def product_params
    params.require(:product).permit(:name, :cogs)
  end
end
