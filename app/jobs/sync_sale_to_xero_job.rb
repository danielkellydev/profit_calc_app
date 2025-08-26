class SyncSaleToXeroJob < ApplicationJob
  queue_as :default

  def perform(sale)
    return unless sale.sale_type&.sync_to_xero?
    return unless sale.user.xero_access_token.present?
    
    xero_service = XeroService.new(sale.user)
    xero_service.create_payment(sale)
    
    Rails.logger.info "Successfully synced sale #{sale.id} to Xero"
  rescue => e
    Rails.logger.error "Failed to sync sale #{sale.id} to Xero: #{e.message}"
    raise # Re-raise to trigger retry logic if configured
  end
end