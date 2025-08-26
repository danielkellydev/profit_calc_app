class Sale < ApplicationRecord
  belongs_to :sale_type
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  belongs_to :user
  accepts_nested_attributes_for :sale_items, allow_destroy: true

  validates :sale_type, presence: true
  validates :total_received, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sale_date, presence: true

  after_create :sync_to_xero
  
  private
  
  def sync_to_xero
    return unless sale_type&.sync_to_xero?
    return unless user.xero_access_token.present?
    
    SyncSaleToXeroJob.perform_later(self)
  rescue => e
    Rails.logger.error "Failed to queue Xero sync for sale #{id}: #{e.message}"
  end
end