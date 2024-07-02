class AddUserIdToCustomPeriods < ActiveRecord::Migration[7.0]
  def change
    add_reference :custom_periods, :user, null: true, foreign_key: true
  end
end
