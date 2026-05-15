module DefaultExpenseCategories
  CATEGORIES = [
    { name: 'Raw Materials',                  business_use_percentage: 100, description: 'COGS — materials consumed in production.' },
    { name: 'Packaging',                      business_use_percentage: 100 },
    { name: 'Postage & Freight',              business_use_percentage: 100 },
    { name: 'WooCommerce / Hosting Fees',     business_use_percentage: 100 },
    { name: 'Bank & Payment Fees',            business_use_percentage: 100 },
    { name: 'Tools & Equipment',              business_use_percentage: 100 },
    { name: 'Software & Subscriptions',       business_use_percentage: 100 },
    { name: 'Accounting & Professional Fees', business_use_percentage: 100 },
    { name: 'Electricity',                    business_use_percentage: 25,  description: 'Apportioned by floor area used for business.' },
    { name: 'Internet',                       business_use_percentage: 70 },
    { name: 'Mobile Phone',                   business_use_percentage: 80 },
    { name: 'Rent / Mortgage Interest',       business_use_percentage: 25,  description: 'Occupancy expenses — confirm method with your accountant.' },
    { name: 'Home Insurance',                 business_use_percentage: 25 },
    { name: 'Motor Vehicle',                  business_use_percentage: 0,   description: 'Log km separately; set % only if claiming a portion of running costs.' }
  ].freeze

  module_function

  def seed(user)
    CATEGORIES.each do |attrs|
      next if user.expense_categories.exists?(name: attrs[:name])

      user.expense_categories.create!(attrs)
    end
  end
end
