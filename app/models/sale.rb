class Sale < ApplicationRecord
  has_many :sale_items
  has_many :products, through: :sale_items

  accepts_nested_attributes_for :sale_items
end