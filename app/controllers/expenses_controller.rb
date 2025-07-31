class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @expenses = current_user.expenses.includes(:expense_category).order(:name)
    @total_weekly_expenses = @expenses.active.sum(&:weekly_amount)
    @total_monthly_expenses = @expenses.active.sum(&:monthly_amount)
    @total_annual_expenses = @expenses.active.sum(&:annual_amount)
    
    @expenses_by_category = @expenses.active.group_by(&:expense_category)
  end

  def show
  end

  def new
    @expense = current_user.expenses.build
    @expense_categories = current_user.expense_categories.order(:name)
  end

  def create
    @expense = current_user.expenses.build(expense_params)
    @expense_categories = current_user.expense_categories.order(:name)
    
    if @expense.save
      redirect_to expenses_path, notice: 'Expense was successfully created.'
    else
      render :new
    end
  end

  def edit
    @expense_categories = current_user.expense_categories.order(:name)
  end

  def update
    @expense_categories = current_user.expense_categories.order(:name)
    
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: 'Expense was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: 'Expense was successfully deleted.'
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:name, :amount, :frequency, :start_date, :end_date, :active, :expense_category_id)
  end
end