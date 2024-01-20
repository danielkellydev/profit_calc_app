class AddCogsToSaleItems < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_items, :cogs, :decimal
  end
end
