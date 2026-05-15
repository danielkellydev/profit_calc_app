module FinancialYear
  module_function

  def current(today = Date.current)
    if today.month >= 7
      Date.new(today.year, 7, 1)..Date.new(today.year + 1, 6, 30)
    else
      Date.new(today.year - 1, 7, 1)..Date.new(today.year, 6, 30)
    end
  end

  def for_year(start_year)
    Date.new(start_year, 7, 1)..Date.new(start_year + 1, 6, 30)
  end

  def from_param(value, fallback: current)
    return fallback if value.blank?

    year = value.to_i
    return fallback if year < 2000 || year > 2100

    for_year(year)
  end

  def label(range)
    "FY#{range.last.year}"
  end

  def start_year(range)
    range.first.year
  end
end
