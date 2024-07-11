class ResetAllTables < ActiveRecord::Migration[6.0]
  def up
    # This will drop all tables and recreate them according to schema.rb
    load(Rails.root.join("db", "schema.rb"))
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end