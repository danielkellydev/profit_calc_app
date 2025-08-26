class SaleTypesController < ApplicationController
  before_action :set_sale_type, only: [:edit, :update, :destroy]

  def index
    @sale_types = current_user.sale_types.all
  end

  def new
    @sale_type = current_user.sale_types.new
  end

  def create
    @sale_type = current_user.sale_types.new(sale_type_params)
    if @sale_type.save
      redirect_to sale_types_path, notice: 'Sale type was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sale_type.update(sale_type_params)
      respond_to do |format|
        format.html { redirect_to sale_types_path, notice: 'Sale type was successfully updated.' }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@sale_type, partial: "sale_types/sale_type", locals: { sale_type: @sale_type }) }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@sale_type, partial: "sale_types/edit_form", locals: { sale_type: @sale_type }) }
      end
    end
  end

  def destroy
    @sale_type.destroy
    redirect_to sale_types_path, notice: 'Sale type was successfully deleted.'
  end

  private

  def set_sale_type
    @sale_type = current_user.sale_types.find(params[:id])
  end

  def sale_type_params
    params.require(:sale_type).permit(:name, :sync_to_xero, :xero_account_code, :xero_account_name, :xero_revenue_account_code)
  end
end