class DashboardController < ApplicationController
  before_action :set_weekly_data, only: [:index, :weekly_history]

  def index
    set_weekly_data
    get_specific_revenue
    @products = current_user.products.all
    current_week = Date.today.cweek
    current_year = Date.today.year
    @sales = current_user.sales.where("EXTRACT(WEEK FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", current_week, current_year)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(sale_items: :product).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs 
    @nuanced_data = @sales.joins(:sale_type).group('sale_types.name').sum(:total_received)
    @weekly_history = @sales
  end

  def get_specific_revenue
    sales = current_user.sales.where(week_of_year: Date.today.cweek, year: Date.today.year)
    @sale_type_revenues = current_user.sale_types.all.map do |sale_type|
      {
        name: sale_type.name,
        revenue: sales.where(sale_type_id: sale_type.id).sum(:total_received)
      }
    end
  end

  def weekly_history
    @weekly_history = current_user.sales.group("EXTRACT(WEEK FROM sale_date)", "EXTRACT(YEAR FROM sale_date)")
                          .select("EXTRACT(WEEK FROM sale_date) as week_of_year", 
                                  "EXTRACT(YEAR FROM sale_date) as year", 
                                  "SUM(total_received) as total_revenue")
                          .map do |sale|
      sales = current_user.sales.where("EXTRACT(WEEK FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", sale.week_of_year, sale.year)
      
      sale_type_revenues = current_user.sale_types.all.map do |sale_type|
        {
          name: sale_type.name,
          revenue: sales.where(sale_type_id: sale_type.id).sum(:total_received)
        }
      end

      cogs = current_user.sale_items.joins(:product, :sale)
                     .where("EXTRACT(WEEK FROM sales.sale_date) = ? AND EXTRACT(YEAR FROM sales.sale_date) = ?", sale.week_of_year, sale.year)
                     .sum('sale_items.quantity * products.cogs')
      profit = sale.total_revenue - cogs
      start_date, end_date = get_week_dates(sales)
  
      { week_of_year: sale.week_of_year, year: sale.year, start_date: start_date, end_date: end_date, 
        total_revenue: sale.total_revenue, cogs: cogs, profit: profit, sale_type_revenues: sale_type_revenues }
    end
    @weekly_history = @weekly_history.reject { |data| data[:year].nil? || data[:week_of_year].nil? }
    @weekly_history = @weekly_history.compact.sort_by { |data| [data[:year] || 0, data[:week_of_year] || 0] }.reverse!
  end

  def sales_data
    set_weekly_data
    set_monthly_data
    get_specific_revenue
    get_monthly_specific_revenue
    @custom_periods = current_user.custom_periods
    @sales = current_user.sales.where(week_of_year: Date.today.cweek, year: Date.today.year)
    @monthly_sales = current_user.sales.where(sale_date: Date.today.beginning_of_month..Date.today.end_of_month)
  end

  private

  def set_weekly_data
    @total_revenue = current_user.sales.where(week_of_year: Date.today.cweek).sum(:total_received)
    @cogs = current_user.sale_items.joins(:product, :sale).where(sales: { week_of_year: Date.today.cweek }).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs
  end

  def get_week_dates(sales)
    if sales.first
      start_date = sales.first.sale_date.beginning_of_week
      end_date = sales.first.sale_date.end_of_week
    else
      start_date = nil
      end_date = nil
    end
    [start_date, end_date]
  end

  def set_monthly_data
    current_month = Date.today.month
    current_year = Date.today.year
    @monthly_sales = current_user.sales.where("EXTRACT(MONTH FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", current_month, current_year)
    @monthly_total_revenue = @monthly_sales.sum(:total_received)
    @monthly_cogs = @monthly_sales.joins(sale_items: :product).sum('sale_items.quantity * products.cogs')
    @monthly_profit = @monthly_total_revenue - @monthly_cogs
  end

  def get_monthly_specific_revenue
    current_month = Date.today.month
    current_year = Date.today.year
    monthly_sales = current_user.sales.where("EXTRACT(MONTH FROM sale_date) = ? AND EXTRACT(YEAR FROM sale_date) = ?", current_month, current_year)
    @monthly_sale_type_revenues = current_user.sale_types.all.map do |sale_type|
      {
        name: sale_type.name,
        revenue: monthly_sales.where(sale_type_id: sale_type.id).sum(:total_received)
      }
    end
  end
end