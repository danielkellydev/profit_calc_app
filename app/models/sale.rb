class Sale < ApplicationRecord
  belongs_to :sale_type
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  belongs_to :user

  validates :sale_type, presence: true
  validates :total_received, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sale_date, presence: true
end