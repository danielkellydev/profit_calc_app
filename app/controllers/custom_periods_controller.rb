class CustomPeriodsController < ApplicationController
  before_action :authenticate_user!

  def index
    @custom_periods = current_user.custom_periods.order(:start_date)
  end

  def new
    @custom_period = current_user.custom_periods.new
  end

  def create
    @custom_period = current_user.custom_periods.new(custom_period_params)
    if @custom_period.save
      redirect_to custom_periods_path, notice: 'Custom period created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @custom_period = current_user.custom_periods.find(params[:id])
    @snapshot = current_user.revenue_snapshots.find_by(period_start: @custom_period.start_date, period_end: @custom_period.end_date)
    @revenue = @snapshot&.gross_sales || 0
    expenses_in_period = current_user.expenses.for_period(@custom_period.start_date, @custom_period.end_date)
    @total_paid = expenses_in_period.sum(&:annual_amount)
    @total_claimable = expenses_in_period.sum(&:claimable_annual_amount)
    @net_profit = @revenue - @total_claimable
  end

  def destroy
    @custom_period = current_user.custom_periods.find(params[:id])
    @custom_period.destroy
    redirect_to custom_periods_path, notice: 'Custom period removed.'
  end

  private

  def custom_period_params
    params.require(:custom_period).permit(:name, :start_date, :end_date)
  end
end
