class AddYearToSales < ActiveRecord::Migration[6.0]
  def change
    add_column :sales, :year, :integer
  end
end