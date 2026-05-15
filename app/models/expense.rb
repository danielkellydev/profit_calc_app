class Expense < ApplicationRecord
  belongs_to :expense_category
  belongs_to :user

  has_many_attached :receipts

  RECEIPT_CONTENT_TYPES = %w[application/pdf image/jpeg image/png image/heic image/heif image/webp].freeze
  RECEIPT_MAX_BYTES = 10.megabytes

  FREQUENCIES = %w[weekly monthly annually one_off].freeze

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
  validates :start_date, presence: { message: "is required for one-off purchases" }, if: :one_off?
  validates :business_use_percentage,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  validate :validate_receipts

  before_validation :sync_one_off_dates

  scope :active, -> { where(active: true) }
  scope :for_period, ->(start_date, end_date) {
    active.where(
      '(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)',
      end_date, start_date
    )
  }

  def one_off?
    frequency == 'one_off'
  end

  def weekly_amount
    return 0 if one_off?

    case frequency
    when 'weekly'   then amount
    when 'monthly'  then amount / 4.33
    when 'annually' then amount / 52
    end
  end

  def monthly_amount
    return 0 if one_off?

    case frequency
    when 'weekly'   then amount * 4.33
    when 'monthly'  then amount
    when 'annually' then amount / 12
    end
  end

  def annual_amount
    case frequency
    when 'weekly'   then amount * 52
    when 'monthly'  then amount * 12
    when 'annually' then amount
    when 'one_off'  then amount
    end
  end

  def effective_business_use_percentage
    business_use_percentage || expense_category&.business_use_percentage || 100
  end

  def business_use_percentage_overridden?
    !business_use_percentage.nil?
  end

  def claimable_amount
    amount * effective_business_use_percentage / 100.0
  end

  def claimable_weekly_amount
    weekly_amount * effective_business_use_percentage / 100.0
  end

  def claimable_monthly_amount
    monthly_amount * effective_business_use_percentage / 100.0
  end

  def claimable_annual_amount
    annual_amount * effective_business_use_percentage / 100.0
  end

  private

  def sync_one_off_dates
    self.end_date = start_date if one_off? && start_date.present?
  end

  def validate_receipts
    return unless receipts.attached?

    receipts.each do |receipt|
      unless RECEIPT_CONTENT_TYPES.include?(receipt.blob.content_type)
        errors.add(:receipts, "must be a PDF or image (was #{receipt.blob.content_type})")
      end
      if receipt.blob.byte_size > RECEIPT_MAX_BYTES
        errors.add(:receipts, "#{receipt.blob.filename} is over 10 MB")
      end
    end
  end
end
