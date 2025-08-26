class AddXeroRevenueAccountToSaleTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_types, :xero_revenue_account_code, :string
  end
end
