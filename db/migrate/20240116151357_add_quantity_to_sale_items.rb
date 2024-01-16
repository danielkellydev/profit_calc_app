class AddQuantityToSaleItems < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_items, :quantity, :integer, default: 0
  end
end