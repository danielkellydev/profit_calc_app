class SaleType < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
end
