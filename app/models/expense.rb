class Expense < ApplicationRecord
  belongs_to :expense_category
  belongs_to :user
  
  FREQUENCIES = ['weekly', 'monthly', 'annually'].freeze
  
  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
  
  scope :active, -> { where(active: true) }
  scope :for_period, ->(start_date, end_date) {
    active.where(
      '(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)', 
      end_date, start_date
    )
  }
  
  # Calculate weekly amount based on frequency
  def weekly_amount
    case frequency
    when 'weekly'
      amount
    when 'monthly'
      amount / 4.33 # Average weeks per month
    when 'annually'
      amount / 52
    end
  end
  
  # Calculate monthly amount based on frequency
  def monthly_amount
    case frequency
    when 'weekly'
      amount * 4.33
    when 'monthly'
      amount
    when 'annually'
      amount / 12
    end
  end
  
  # Calculate annual amount based on frequency
  def annual_amount
    case frequency
    when 'weekly'
      amount * 52
    when 'monthly'
      amount * 12
    when 'annually'
      amount
    end
  end
end