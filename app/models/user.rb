class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :custom_periods
  has_many :expense_categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_one  :woocommerce_config, dependent: :destroy
  has_many :revenue_snapshots, dependent: :destroy

  after_create :seed_default_expense_categories

  def weekly_expenses(start_date = nil, end_date = nil)
    scope = start_date && end_date ? expenses.for_period(start_date, end_date) : expenses.active
    scope.sum(&:weekly_amount)
  end

  def monthly_expenses(start_date = nil, end_date = nil)
    scope = start_date && end_date ? expenses.for_period(start_date, end_date) : expenses.active
    scope.sum(&:monthly_amount)
  end

  def claimable_monthly_expenses(start_date = nil, end_date = nil)
    scope = start_date && end_date ? expenses.for_period(start_date, end_date) : expenses.active
    scope.sum(&:claimable_monthly_amount)
  end

  def claimable_annual_expenses(start_date = nil, end_date = nil)
    scope = start_date && end_date ? expenses.for_period(start_date, end_date) : expenses.active
    scope.sum(&:claimable_annual_amount)
  end

  def expense_breakdown_percentage(start_date = nil, end_date = nil)
    total = claimable_monthly_expenses(start_date, end_date)
    return [] if total.zero?

    expense_categories.includes(:expenses).map do |category|
      category_total = category.expenses.active.sum(&:claimable_monthly_amount)
      {
        name: category.name,
        percentage: (category_total / total * 100).round(1),
        amount: category_total
      }
    end.reject { |c| c[:amount].zero? }.sort_by { |c| -c[:percentage] }
  end

  private

  def seed_default_expense_categories
    DefaultExpenseCategories.seed(self)
  end
end
