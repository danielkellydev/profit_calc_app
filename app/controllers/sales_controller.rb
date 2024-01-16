class SalesController < ApplicationController
  def destroy
    @sale = Sale.find(params[:id])
    @sale.destroy
    redirect_to dashboard_index_path, notice: 'Sale was successfully deleted.'
  end

  def edit
    @sale = Sale.find(params[:id])
  end

  def update
    @sale = Sale.find(params[:id])
    if @sale.update(sale_params)
      redirect_to dashboard_index_path, turbo_frame: 'sales_record_frame', notice: 'Sale was successfully updated.'
    else
      render :edit, turbo_frame: 'sales_record_frame'
    end
  end

  private

  def sale_params
    params.require(:sale).permit(:sale_type, :total_received, sale_items_attributes: [:id, :quantity, :product_id])
  end
end