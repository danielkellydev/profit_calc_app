class AddUserToSales < ActiveRecord::Migration[7.0]
  def change
    add_reference :sales, :user, null: true, foreign_key: true
  end
end
