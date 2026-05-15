module DashboardHelper
  def fy_options(selected_range)
    selected_year = FinancialYear.start_year(selected_range)
    current_year = FinancialYear.start_year(FinancialYear.current)
    years = (current_year - 4..current_year + 1).to_a.reverse
    options_for_select(years.map { |y| ["FY#{y + 1}", y] }, selected_year)
  end
end
