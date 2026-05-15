class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @expenses = current_user.expenses.includes(:expense_category).with_attached_receipts.order(:name)
    @total_weekly_expenses    = @expenses.active.sum(&:weekly_amount)
    @total_monthly_expenses   = @expenses.active.sum(&:monthly_amount)
    @total_annual_expenses    = @expenses.active.sum(&:annual_amount)
    @total_claimable_monthly  = @expenses.active.sum(&:claimable_monthly_amount)
    @total_claimable_annual   = @expenses.active.sum(&:claimable_annual_amount)
    @expenses_by_category = @expenses.active.group_by(&:expense_category)
    @new_expense = current_user.expenses.build(active: true, frequency: 'monthly')
    @expense_categories = current_user.expense_categories.order(:name)
  end

  def show
  end

  def new
    @expense = current_user.expenses.build(active: true, frequency: 'monthly')
    @expense_categories = current_user.expense_categories.order(:name)
  end

  def create
    @expense = current_user.expenses.build(expense_params)
    @expense_categories = current_user.expense_categories.order(:name)

    if @expense.save
      redirect_to expenses_path, notice: 'Expense added.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @expense_categories = current_user.expense_categories.order(:name)
  end

  def update
    @expense_categories = current_user.expense_categories.order(:name)

    if @expense.update(expense_params)
      redirect_to expenses_path, notice: 'Expense updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: 'Expense deleted.'
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(
      :name, :amount, :frequency, :start_date, :end_date, :active,
      :expense_category_id, :business_use_percentage,
      receipts: []
    )
  end
end
