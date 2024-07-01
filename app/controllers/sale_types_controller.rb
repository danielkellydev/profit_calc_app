# app/controllers/sale_types_controller.rb
class SaleTypesController < ApplicationController
  def index
    @sale_types = current_user.sale_types.all
  end

  def new
    @sale_type = current_user.sale_types.new
  end

  def create
    @sale_type = current_user.sale_types.new(sale_type_params)

    if @sale_type.save
      redirect_to new_sale_path, notice: 'Sale type was successfully created.'
    else
      render :new
    end
  end

  def edit
    @sale_type = SaleType.find(params[:id])
  end

  def update
    @sale_type = SaleType.find(params[:id])
    if @sale_type.update(sale_type_params)
      redirect_to sale_types_path, notice: 'Sale type was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @sale_type = SaleType.find(params[:id])
    @sale_type.destroy
    redirect_to sale_types_path, notice: 'Sale type was successfully deleted.'
  end

  private

  def sale_type_params
    params.require(:sale_type).permit(:name)
  end
end