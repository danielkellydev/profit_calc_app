class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :frequency, null: false
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: true
      t.references :expense_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :expenses, :active
    add_index :expenses, :frequency
  end
end
