class ProductsController < ApplicationController

  def create
    @product = current_user.products.new(product_params)
    if @product.save
      redirect_to edit_all_products_path
    else
      render :new
    end
  end
  
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to edit_all_products_path
  end

  def edit
    @product = Product.find(params[:id])
    @products = Product.all
  end

  def edit_all
    @products = current_user.products.all
  end

  def update
    @product = Product.find(params[:id])
  
    if @product.update(product_params)
      @products = Product.all # Fetch all products again after updating
      render :edit_all # Render the edit view
    else
      render :edit_all
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :cogs)
  end
end