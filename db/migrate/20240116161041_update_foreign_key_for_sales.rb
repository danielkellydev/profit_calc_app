class UpdateForeignKeyForSales < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :sales, :products
    add_foreign_key :sales, :products, on_delete: :cascade
  end
end