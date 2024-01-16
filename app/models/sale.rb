class Sale < ApplicationRecord
  has_many :transactions 
  has_many :products, through: :transactions
end
