# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_08_26_145400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "custom_periods", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_custom_periods_on_user_id"
  end

  create_table "expense_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_expense_categories_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "frequency", null: false
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true
    t.bigint "expense_category_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_expenses_on_active"
    t.index ["expense_category_id"], name: "index_expenses_on_expense_category_id"
    t.index ["frequency"], name: "index_expenses_on_frequency"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.decimal "cogs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "sale_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity", default: 0
    t.decimal "price"
    t.decimal "cogs"
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sale_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "sync_to_xero"
    t.string "xero_account_code"
    t.string "xero_account_name"
    t.string "xero_revenue_account_code"
    t.index ["user_id"], name: "index_sale_types_on_user_id"
  end

  create_table "sales", force: :cascade do |t|
    t.decimal "total_received"
    t.integer "week_of_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id"
    t.integer "quantity"
    t.decimal "total_revenue"
    t.integer "year"
    t.date "sale_date"
    t.bigint "sale_type_id"
    t.string "old_sale_type"
    t.bigint "user_id"
    t.index ["product_id"], name: "index_sales_on_product_id"
    t.index ["sale_type_id"], name: "index_sales_on_sale_type_id"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "xero_access_token"
    t.text "xero_refresh_token"
    t.datetime "xero_token_expires_at"
    t.string "xero_tenant_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "custom_periods", "users"
  add_foreign_key "expense_categories", "users"
  add_foreign_key "expenses", "expense_categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "products", "users"
  add_foreign_key "sale_items", "products", on_delete: :cascade
  add_foreign_key "sale_items", "sales", on_delete: :nullify
  add_foreign_key "sale_types", "users"
  add_foreign_key "sales", "products", on_delete: :cascade
  add_foreign_key "sales", "sale_types"
  add_foreign_key "sales", "users"
end
