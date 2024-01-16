class AddProductToSales < ActiveRecord::Migration[6.1]
  def change
    add_reference :sales, :product, null: true, foreign_key: true

    # Set a default product_id for existing sales
    # Replace `1` with the id of the product you want to associate with existing sales
    Sale.update_all(product_id: 1)

    change_column_null :sales, :product_id, false
  end
end