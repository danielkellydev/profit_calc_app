# Ensure every existing user has the default expense categories.
# New signups get them automatically via User#seed_default_expense_categories.
User.find_each do |user|
  DefaultExpenseCategories.seed(user)
end
