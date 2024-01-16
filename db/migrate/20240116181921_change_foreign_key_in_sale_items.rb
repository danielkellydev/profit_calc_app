class ChangeForeignKeyInSaleItems < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :sale_items, :sales
    add_foreign_key :sale_items, :sales, on_delete: :nullify
  end
end
