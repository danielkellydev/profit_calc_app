class AddXeroTokensToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :xero_access_token, :text
    add_column :users, :xero_refresh_token, :text
    add_column :users, :xero_token_expires_at, :datetime
    add_column :users, :xero_tenant_id, :string
  end
end
