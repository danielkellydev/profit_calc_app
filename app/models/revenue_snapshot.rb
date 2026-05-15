class RevenueSnapshot < ApplicationRecord
  belongs_to :user

  validates :period_start, :period_end, :fetched_at, presence: true
  validate :period_end_after_period_start

  def stale?(now = Time.current)
    threshold = period_end >= Date.current ? 1.hour : 24.hours
    fetched_at < now - threshold
  end

  private

  def period_end_after_period_start
    return if period_start.blank? || period_end.blank?

    errors.add(:period_end, 'must be on or after period_start') if period_end < period_start
  end
end
