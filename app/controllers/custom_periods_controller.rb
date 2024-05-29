class CustomPeriodsController < ApplicationController
  def index
    @custom_periods = CustomPeriod.all
  end

  def new
    @custom_period = CustomPeriod.new
  end

  def create
    @custom_period = CustomPeriod.new(custom_period_params)
    if @custom_period.save
      redirect_to custom_periods_path, notice: 'Custom period was successfully created.'
    else
      render :new
    end
  end

  def show
    @custom_period = CustomPeriod.find(params[:id])
    @sales = Sale.where(sale_date: @custom_period.start_date..@custom_period.end_date)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(sale_items: :product).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs

    @new_face_to_face_revenue = @sales.where(sale_type: 'new face to face').sum(:total_received)
    @return_face_to_face_revenue = @sales.where(sale_type: 'return face to face').sum(:total_received)
    @online_revenue = @sales.where(sale_type: 'online').sum(:total_received)
  end

  private

  def custom_period_params
    params.require(:custom_period).permit(:name, :start_date, :end_date)
  end
end