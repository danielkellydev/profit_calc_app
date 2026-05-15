class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @fy = FinancialYear.from_param(params[:fy])
    load_dashboard_data
  end

  def refresh_woocommerce
    @fy = FinancialYear.from_param(params[:fy])
    if current_user.woocommerce_config&.configured?
      begin
        WoocommerceService.new(current_user).period_revenue(@fy.first, @fy.last, force: true)
        flash[:notice] = "Refreshed revenue from WooCommerce."
      rescue WoocommerceService::AuthenticationError => e
        current_user.woocommerce_config.record_failure!('auth_error', e.message)
        flash[:alert] = "WooCommerce rejected credentials — check key/secret in Settings."
      rescue WoocommerceService::StoreUnreachableError => e
        current_user.woocommerce_config.record_failure!('unreachable', e.message)
        flash[:alert] = "Could not reach the WooCommerce store."
      rescue WoocommerceService::Error => e
        current_user.woocommerce_config.record_failure!('unreachable', e.message)
        flash[:alert] = "WooCommerce sync failed: #{e.message}"
      end
    else
      flash[:alert] = "Configure WooCommerce in Settings first."
    end
    redirect_to dashboard_index_path(fy: FinancialYear.start_year(@fy))
  end

  private

  def load_dashboard_data
    @snapshot = current_user.revenue_snapshots.find_by(period_start: @fy.first, period_end: @fy.last)
    @revenue = @snapshot&.gross_sales || 0
    @total_paid = expenses_in_period.sum(&:annual_amount)
    @total_claimable = expenses_in_period.sum(&:claimable_annual_amount)
    @net_profit = @revenue - @total_claimable
    @category_breakdown = current_user.expense_breakdown_percentage(@fy.first, @fy.last)
    @woocommerce_configured = current_user.woocommerce_config&.configured?
  end

  def expenses_in_period
    current_user.expenses.for_period(@fy.first, @fy.last)
  end
end
