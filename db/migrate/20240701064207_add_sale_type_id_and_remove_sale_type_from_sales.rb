class AddSaleTypeIdAndRemoveSaleTypeFromSales < ActiveRecord::Migration[6.1]
  def change
    add_reference :sales, :sale_type, null: true, foreign_key: true
    
    # Temporarily change sale_type to allow null values
    change_column_null :sales, :sale_type, true

    # Add this to store old sale_type values
    add_column :sales, :old_sale_type, :string
  end
end