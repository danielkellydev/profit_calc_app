class CreateRevenueSnapshots < ActiveRecord::Migration[7.0]
  def change
    create_table :revenue_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.decimal :gross_sales, precision: 12, scale: 2, default: 0, null: false
      t.decimal :net_sales,   precision: 12, scale: 2, default: 0, null: false
      t.integer :order_count, default: 0, null: false
      t.datetime :fetched_at, null: false
      t.timestamps

      t.index [:user_id, :period_start, :period_end], unique: true, name: 'index_revenue_snapshots_on_user_and_period'
    end
  end
end
