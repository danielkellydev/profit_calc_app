class AddQuantityToSales < ActiveRecord::Migration[7.0]
  def change
    add_column :sales, :quantity, :integer
  end
end
