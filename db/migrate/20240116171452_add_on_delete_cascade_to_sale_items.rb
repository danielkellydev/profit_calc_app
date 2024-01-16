class AddOnDeleteCascadeToSaleItems < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :sale_items, :products
    add_foreign_key :sale_items, :products, on_delete: :cascade
  end
end