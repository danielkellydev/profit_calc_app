class CreateSaleTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :sale_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
