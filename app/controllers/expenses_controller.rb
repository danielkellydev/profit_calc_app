class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @fy = FinancialYear.from_param(params[:fy])
    @expense_categories = current_user.expense_categories.order(:name)

    all_expenses = current_user.expenses.includes(:expense_category).with_attached_receipts

    one_off_scope = all_expenses.active.where(frequency: 'one_off').for_period(@fy.first, @fy.last)
    @one_offs = one_off_scope.sort_by { |e| e.start_date || Date.new(0) }.reverse

    @recurring_by_category = all_expenses.active.where.not(frequency: 'one_off').order(:name).group_by(&:expense_category)
    @recurring_count = @recurring_by_category.values.sum(&:size)

    fy_expenses = all_expenses.for_period(@fy.first, @fy.last)
    @one_off_fy_total      = @one_offs.sum(&:amount)
    @claimable_fy_total    = fy_expenses.sum(&:claimable_annual_amount)
    @recurring_annual_total = fy_expenses.reject(&:one_off?).sum(&:claimable_annual_amount)

    @new_one_off = current_user.expenses.build(
      active: true,
      frequency: 'one_off',
      start_date: Date.current
    )
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
