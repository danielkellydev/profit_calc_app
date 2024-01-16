class DashboardController < ApplicationController
  def index
    @sales = Sale.where(week_of_year: Date.today.cweek)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(:products).sum(:cogs)
    @profit = @total_revenue - @cogs 
    @nuanced_data = @sales.group(:sale_type).sum(:total_received)
  end
end
