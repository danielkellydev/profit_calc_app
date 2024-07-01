class AddUserToSaleTypes < ActiveRecord::Migration[7.0]
  def change
    add_reference :sale_types, :user, null: true, foreign_key: true
  end
end
