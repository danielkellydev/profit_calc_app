class DashboardController < ApplicationController
  before_action :set_weekly_data, only: [:index, :weekly_history]

  def index
    set_weekly_data
    get_specific_revenue
    @products = Product.all
    current_week = Date.today.cweek
    current_year = Date.today.year
    @sales = Sale.where("EXTRACT(WEEK FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", current_week, current_year)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(sale_items: :product).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs 
    @nuanced_data = @sales.group(:sale_type).sum(:total_received)
    @weekly_history = @sales
  end

  def get_specific_revenue
    sales = Sale.where(week_of_year: Date.today.cweek, year: Date.today.year)
    @new_face_to_face_revenue = sales.where(sale_type: 'new face to face').sum(:total_received)
    @return_face_to_face_revenue = sales.where(sale_type: 'return face to face').sum(:total_received)
    @online_revenue = sales.where(sale_type: 'online').sum(:total_received)
  end

  def weekly_history
    @weekly_history = Sale.group("EXTRACT(WEEK FROM sale_date)", "EXTRACT(YEAR FROM sale_date)").select("EXTRACT(WEEK FROM sale_date) as week_of_year", "EXTRACT(YEAR FROM sale_date) as year", "SUM(total_received) as total_revenue").map do |sale|
      sales = Sale.where("EXTRACT(WEEK FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", sale.week_of_year, sale.year)
      new_face_to_face_revenue = sales.where(sale_type: 'new face to face').sum(:total_received)
      return_face_to_face_revenue = sales.where(sale_type: 'return face to face').sum(:total_received)
      online_revenue = sales.where(sale_type: 'online').sum(:total_received)
  
      cogs = SaleItem.joins(:product, :sale).where("EXTRACT(WEEK FROM sales.sale_date) = ? AND EXTRACT(YEAR FROM sales.sale_date) = ?", sale.week_of_year, sale.year).sum('sale_items.quantity * products.cogs')
      profit = sale.total_revenue - cogs
      if sales.first
        start_date = sales.first.sale_date.beginning_of_week
        end_date = sales.first.sale_date.end_of_week
      else
        start_date = nil
        end_date = nil
      end
  
      { week_of_year: sale.week_of_year, year: sale.year, start_date: start_date, end_date: end_date, total_revenue: sale.total_revenue, cogs: cogs, profit: profit, new_face_to_face_revenue: new_face_to_face_revenue, return_face_to_face_revenue: return_face_to_face_revenue, online_revenue: online_revenue }
    end
  end

  private

  def set_weekly_data
    @total_revenue = Sale.where(week_of_year: Date.today.cweek).sum(:total_received)
    @cogs = SaleItem.joins(:product, :sale).where(sales: { week_of_year: Date.today.cweek }).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs
  end
end
