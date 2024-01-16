class RenameTransactionsToSaleItems < ActiveRecord::Migration[7.0]
  def change
    rename_table :transactions, :sale_items
  end
end