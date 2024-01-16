class AddTotalRevenueToSales < ActiveRecord::Migration[7.0]
  def change
    add_column :sales, :total_revenue, :decimal
  end
end
