class DropLegacyAndXero < ActiveRecord::Migration[7.0]
  def up
    drop_table :sale_items, if_exists: true
    drop_table :sales, if_exists: true
    drop_table :products, if_exists: true
    drop_table :sale_types, if_exists: true

    remove_column :users, :xero_access_token, if_exists: true
    remove_column :users, :xero_refresh_token, if_exists: true
    remove_column :users, :xero_token_expires_at, if_exists: true
    remove_column :users, :xero_tenant_id, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Legacy sales/products/Xero tables and columns have been removed permanently."
  end
end
