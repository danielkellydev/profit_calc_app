class AssociateExistingSaleTypesToDefaultUser < ActiveRecord::Migration[7.0]
  def up
    # Create a default user if not exists
    user = User.find_or_create_by!(email: 'default@example.com') do |u|
      u.password = SecureRandom.hex(10)
      u.password_confirmation = u.password
    end

    # Associate existing sale types with the default user
    SaleType.where(user_id: nil).update_all(user_id: user.id)

    # Now make user_id non-nullable
    change_column_null :sale_types, :user_id, false
  end

  def down
    change_column_null :sale_types, :user_id, true
  end
end