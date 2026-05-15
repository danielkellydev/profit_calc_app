class AddBusinessUsePercentageToExpenseCategoriesAndExpenses < ActiveRecord::Migration[7.0]
  def change
    add_column :expense_categories, :business_use_percentage,
               :decimal, precision: 5, scale: 2, default: 100, null: false
    add_column :expenses, :business_use_percentage,
               :decimal, precision: 5, scale: 2, null: true
  end
end
