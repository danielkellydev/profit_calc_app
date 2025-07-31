class ExpenseCategory < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
end