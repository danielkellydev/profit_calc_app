class CustomPeriodsController < ApplicationController
  def index
    @custom_periods = current_user.custom_periods
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace('custom', partial: 'custom_periods/index', locals: { custom_periods: @custom_periods }) }
    end
  end

  def new
    @custom_period = current_user.custom_periods.new
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace('custom', partial: 'custom_periods/new', locals: { custom_period: @custom_period }) }
    end
  end

  def create
    @custom_period = current_user.custom_periods.new(custom_period_params)
    if @custom_period.save
      respond_to do |format|
        format.html { redirect_to custom_periods_path, notice: 'Custom period was successfully created.' }
        format.turbo_stream { 
          flash.now[:notice] = 'Custom period was successfully created.'
          render turbo_stream: turbo_stream.replace('custom', partial: 'custom_periods/index', locals: { custom_periods: current_user.custom_periods })
        }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('custom', partial: 'custom_periods/new', locals: { custom_period: @custom_period }) }
      end
    end
  end

  def show
    @custom_period = current_user.custom_periods.find(params[:id])
    @sales = current_user.sales.where(sale_date: @custom_period.start_date..@custom_period.end_date)
    @total_revenue = @sales.sum(:total_received)
    @cogs = @sales.joins(sale_items: :product).sum('sale_items.quantity * products.cogs')
    @profit = @total_revenue - @cogs

    @sale_type_revenues = current_user.sale_types.map do |sale_type|
      {
        name: sale_type.name,
        revenue: @sales.where(sale_type: sale_type).sum(:total_received)
      }
    end

    respond_to do |format|
      format.html
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace('custom', 
          partial: 'custom_periods/show', 
          locals: { 
            custom_period: @custom_period, 
            total_revenue: @total_revenue, 
            cogs: @cogs, 
            profit: @profit, 
            sale_type_revenues: @sale_type_revenues 
          }
        ) 
      }
    end
  end

  private

  def custom_period_params
    params.require(:custom_period).permit(:name, :start_date, :end_date)
  end
end