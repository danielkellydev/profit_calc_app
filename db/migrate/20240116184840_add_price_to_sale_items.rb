class AddPriceToSaleItems < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_items, :price, :decimal
  end
end
