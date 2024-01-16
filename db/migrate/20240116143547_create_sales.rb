class CreateSales < ActiveRecord::Migration[7.0]
  def change
    create_table :sales do |t|
      t.decimal :total_received
      t.string :sale_type
      t.integer :week_of_year

      t.timestamps
    end
  end
end
