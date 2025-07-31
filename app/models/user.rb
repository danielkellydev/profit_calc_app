class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :sales
  has_many :products 
  has_many :sale_types 
  has_many :sale_items, through: :sales
  has_many :custom_periods
  has_many :expense_categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  
  def weekly_expenses(start_date = nil, end_date = nil)
    if start_date && end_date
      expenses.for_period(start_date, end_date).sum(&:weekly_amount)
    else
      expenses.active.sum(&:weekly_amount)
    end
  end
  
  def monthly_expenses(start_date = nil, end_date = nil)
    if start_date && end_date
      expenses.for_period(start_date, end_date).sum(&:monthly_amount)
    else
      expenses.active.sum(&:monthly_amount)
    end
  end
  
  # Calculate weekly averages
  def weekly_average_revenue(weeks_back = 12)
    start_date = weeks_back.weeks.ago.beginning_of_week
    weekly_totals = sales.where('sale_date >= ?', start_date)
                         .group("EXTRACT(WEEK FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                         .sum(:total_received)
    return 0 if weekly_totals.empty?
    weekly_totals.values.sum / weekly_totals.count.to_f
  end
  
  def weekly_average_profit(weeks_back = 12)
    start_date = weeks_back.weeks.ago.beginning_of_week
    weekly_data = sales.joins(sale_items: :product)
                       .where('sale_date >= ?', start_date)
                       .group("EXTRACT(WEEK FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                       .select("EXTRACT(WEEK FROM sale_date) as week, EXTRACT(YEAR FROM sale_date) as year",
                               "SUM(sales.total_received) as revenue",
                               "SUM(sale_items.quantity * products.cogs) as cogs")
    
    weekly_results = weekly_data.to_a
    return 0 if weekly_results.empty?
    
    total_profit = weekly_results.sum { |week| week.revenue - week.cogs }
    avg_expenses = weekly_expenses
    avg_gross_profit = total_profit / weekly_results.length.to_f
    avg_gross_profit - avg_expenses
  end
  
  # Calculate monthly averages
  def monthly_average_revenue(months_back = 12)
    start_date = months_back.months.ago.beginning_of_month
    monthly_totals = sales.where('sale_date >= ?', start_date)
                          .group("EXTRACT(MONTH FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                          .sum(:total_received)
    return 0 if monthly_totals.empty?
    monthly_totals.values.sum / monthly_totals.count.to_f
  end
  
  def monthly_average_profit(months_back = 12)
    start_date = months_back.months.ago.beginning_of_month
    monthly_data = sales.joins(sale_items: :product)
                        .where('sale_date >= ?', start_date)
                        .group("EXTRACT(MONTH FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                        .select("EXTRACT(MONTH FROM sale_date) as month, EXTRACT(YEAR FROM sale_date) as year",
                                "SUM(sales.total_received) as revenue",
                                "SUM(sale_items.quantity * products.cogs) as cogs")
    
    monthly_results = monthly_data.to_a
    return 0 if monthly_results.empty?
    
    total_profit = monthly_results.sum { |month| month.revenue - month.cogs }
    avg_expenses = monthly_expenses
    avg_gross_profit = total_profit / monthly_results.length.to_f
    avg_gross_profit - avg_expenses
  end
  
  # Business analysis methods
  def profit_margin(period = :monthly)
    avg_revenue = period == :weekly ? weekly_average_revenue : monthly_average_revenue
    avg_profit = period == :weekly ? weekly_average_profit : monthly_average_profit
    return 0 if avg_revenue == 0
    (avg_profit / avg_revenue * 100).round(2)
  end
  
  def expense_ratio(period = :monthly)
    avg_revenue = period == :weekly ? weekly_average_revenue : monthly_average_revenue
    avg_expenses = period == :weekly ? weekly_expenses : monthly_expenses
    return 0 if avg_revenue == 0
    (avg_expenses / avg_revenue * 100).round(2)
  end
  
  def revenue_growth_rate(period = :monthly)
    if period == :monthly
      current = monthly_average_revenue_with_offset(3, 0) # Last 3 months
      previous = monthly_average_revenue_with_offset(3, 3) # Previous 3 months (months 4-6 ago)
    else
      current = weekly_average_revenue_with_offset(6, 0) # Last 6 weeks
      previous = weekly_average_revenue_with_offset(6, 6) # Previous 6 weeks (weeks 7-12 ago)
    end
    
    return 0 if previous == 0
    ((current - previous) / previous * 100).round(2)
  end
  
  def best_performing_month
    monthly_data = sales.joins(sale_items: :product)
                        .where('sale_date >= ?', 12.months.ago)
                        .group("EXTRACT(MONTH FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                        .select("EXTRACT(MONTH FROM sale_date) as month, EXTRACT(YEAR FROM sale_date) as year",
                                "SUM(sales.total_received) as revenue",
                                "SUM(sale_items.quantity * products.cogs) as cogs")
                        .map { |m| { month: m.month.to_i, year: m.year.to_i, profit: m.revenue - m.cogs - monthly_expenses } }
                        .max_by { |m| m[:profit] }
    
    return nil unless monthly_data
    "#{Date::MONTHNAMES[monthly_data[:month]]} #{monthly_data[:year]}"
  end
  
  def sales_by_type_percentage
    total_revenue = sales.sum(:total_received)
    return {} if total_revenue == 0
    
    sale_types.map do |type|
      type_revenue = sales.where(sale_type: type).sum(:total_received)
      {
        name: type.name,
        percentage: (type_revenue / total_revenue * 100).round(1),
        revenue: type_revenue
      }
    end.sort_by { |t| -t[:percentage] }
  end
  
  def expense_breakdown_percentage
    total_expenses = monthly_expenses
    return {} if total_expenses == 0
    
    expense_categories.includes(:expenses).map do |category|
      category_total = category.expenses.active.sum(&:monthly_amount)
      {
        name: category.name,
        percentage: (category_total / total_expenses * 100).round(1),
        amount: category_total
      }
    end.sort_by { |c| -c[:percentage] }
  end
  
  private
  
  def weekly_average_revenue_with_offset(weeks_back, offset = 0)
    start_date = (weeks_back + offset).weeks.ago.beginning_of_week
    end_date = offset.weeks.ago.end_of_week
    weekly_totals = sales.where('sale_date >= ? AND sale_date <= ?', start_date, end_date)
                         .group("EXTRACT(WEEK FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                         .sum(:total_received)
    return 0 if weekly_totals.empty?
    weekly_totals.values.sum / weekly_totals.count.to_f
  end
  
  def monthly_average_revenue_with_offset(months_back, offset = 0)
    start_date = (months_back + offset).months.ago.beginning_of_month
    end_date = offset.months.ago.end_of_month
    monthly_totals = sales.where('sale_date >= ? AND sale_date <= ?', start_date, end_date)
                          .group("EXTRACT(MONTH FROM sale_date), EXTRACT(YEAR FROM sale_date)")
                          .sum(:total_received)
    return 0 if monthly_totals.empty?
    monthly_totals.values.sum / monthly_totals.count.to_f
  end
end
