class RemoveNotNullFromSaleIdInSaleItems < ActiveRecord::Migration[7.0]
  def change
    change_column_null :sale_items, :sale_id, true
  end
end
