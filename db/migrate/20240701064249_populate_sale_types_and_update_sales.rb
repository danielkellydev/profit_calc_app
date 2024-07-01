class PopulateSaleTypesAndUpdateSales < ActiveRecord::Migration[6.1]
  def up
    # Store old sale_type values
    execute "UPDATE sales SET old_sale_type = sale_type"

    # Create SaleType records
    execute "INSERT INTO sale_types (name, created_at, updated_at) SELECT DISTINCT sale_type, NOW(), NOW() FROM sales WHERE sale_type IS NOT NULL"

    # Update sales with new sale_type_id
    execute <<-SQL
      UPDATE sales
      SET sale_type_id = sale_types.id
      FROM sale_types
      WHERE sales.sale_type = sale_types.name
    SQL

    # Remove the old sale_type column
    remove_column :sales, :sale_type
  end

  def down
    add_column :sales, :sale_type, :string

    # Restore old sale_type values
    execute "UPDATE sales SET sale_type = old_sale_type"

    remove_column :sales, :old_sale_type
    remove_reference :sales, :sale_type
  end
end