namespace :db do
  desc "Delete all sales, products, sale types, and sale items"
  task reset_data: :environment do
    puts "Deleting all sales..."
    Sale.destroy_all
    puts "Deleting all products..."
    Product.destroy_all
    puts "Deleting all sale types..."
    SaleType.destroy_all
    puts "Deleting all sale items..."
    SaleItem.destroy_all
    puts "All data has been deleted."
  end
end