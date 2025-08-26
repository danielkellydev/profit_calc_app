class AddXeroFieldsToSaleTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_types, :sync_to_xero, :boolean
    add_column :sale_types, :xero_account_code, :string
    add_column :sale_types, :xero_account_name, :string
  end
end
