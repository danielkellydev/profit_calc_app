class ProductsController < ApplicationController
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to dashboard_index_path, notice: 'Product was successfully deleted.'
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to dashboard_index_path, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :cogs)
  end
end