class ExpenseCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense_category, only: [:show, :edit, :update, :destroy]

  def index
    @expense_categories = current_user.expense_categories.includes(:expenses).order(:name)
  end

  def show
    @expenses = @expense_category.expenses.order(:name)
  end

  def new
    @expense_category = current_user.expense_categories.build
  end

  def create
    @expense_category = current_user.expense_categories.build(expense_category_params)
    
    if @expense_category.save
      redirect_to expense_categories_path, notice: 'Expense category was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @expense_category.update(expense_category_params)
      redirect_to expense_categories_path, notice: 'Expense category was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @expense_category.destroy
    redirect_to expense_categories_path, notice: 'Expense category was successfully deleted.'
  end

  private

  def set_expense_category
    @expense_category = current_user.expense_categories.find(params[:id])
  end

  def expense_category_params
    params.require(:expense_category).permit(:name, :description)
  end
end