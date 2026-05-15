require 'csv'

class ReceiptsController < ApplicationController
  before_action :authenticate_user!

  # DELETE /expenses/:expense_id/receipts/:id — purge one attachment
  def destroy
    expense = current_user.expenses.find(params[:expense_id])
    attachment = expense.receipts.attachments.find(params[:id])
    attachment.purge_later
    redirect_to edit_expense_path(expense), notice: 'Receipt removed.'
  end

  # GET /receipts/export?fy=YYYY — stream zip of all receipts + summary CSV for the FY
  def export
    fy = FinancialYear.from_param(params[:fy])
    fy_label = FinancialYear.label(fy)
    filename = "receipts_#{fy_label.downcase}.zip"

    expenses = current_user.expenses
                           .includes(:expense_category, receipts_attachments: :blob)
                           .for_period(fy.first, fy.last)
                           .order(:start_date, :name)

    zip_bytes = build_zip(expenses, fy, fy_label)

    send_data zip_bytes,
              filename: filename,
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  def build_zip(expenses, fy, fy_label)
    Zip::OutputStream.write_buffer do |zos|
      write_summary_csv(zos, expenses, fy_label)
      write_receipt_files(zos, expenses, fy_label)
    end.string
  end

  def write_summary_csv(zos, expenses, fy_label)
    zos.put_next_entry("#{fy_label}/summary.csv")
    csv = CSV.generate do |row|
      row << %w[date name category amount frequency business_use_pct annual_amount claimable_annual receipt_count]
      expenses.each do |e|
        row << [
          e.start_date,
          e.name,
          e.expense_category.name,
          e.amount.to_s,
          e.frequency,
          e.effective_business_use_percentage,
          e.annual_amount.to_s,
          e.claimable_annual_amount.round(2).to_s,
          e.receipts.size
        ]
      end
    end
    zos.write(csv)
  end

  def write_receipt_files(zos, expenses, fy_label)
    used_names = Hash.new(0)
    expenses.each do |expense|
      expense.receipts.each do |receipt|
        path = receipt_path(expense, receipt, used_names, fy_label)
        zos.put_next_entry(path)
        receipt.blob.download { |chunk| zos.write(chunk) }
      end
    end
  end

  def receipt_path(expense, receipt, used_names, fy_label)
    category = sanitize(expense.expense_category.name)
    date = expense.start_date&.iso8601 || 'undated'
    name = sanitize(expense.name)
    ext = File.extname(receipt.filename.to_s).presence || ".#{receipt.blob.filename.extension || 'bin'}"
    base = "#{date}_#{name}_$#{format('%.2f', expense.amount)}"

    key = "#{fy_label}/#{category}/#{base}#{ext}"
    used_names[key] += 1
    n = used_names[key]
    n > 1 ? "#{fy_label}/#{category}/#{base}_#{n}#{ext}" : key
  end

  def sanitize(str)
    str.to_s.gsub(/[^\w\s.-]/, ' ').squeeze(' ').strip.tr(' ', '_')
  end
end
