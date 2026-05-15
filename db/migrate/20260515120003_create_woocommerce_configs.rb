class CreateWoocommerceConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :woocommerce_configs do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :store_url, null: false
      t.text :consumer_key
      t.text :consumer_secret
      t.datetime :last_synced_at
      t.string :last_sync_status
      t.text :last_sync_error
      t.timestamps
    end
  end
end
