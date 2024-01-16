class RemoveNotNullConstraintFromSales < ActiveRecord::Migration[6.0]
  def change
    change_column_null :sales, :product_id, true
  end
end