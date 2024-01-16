class Product < ApplicationRecord
  has_many :transaction 
  has_many :sales, through: :transaction
end
