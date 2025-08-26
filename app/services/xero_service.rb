require 'net/http'
require 'json'

class XeroService
  def initialize(user)
    @user = user
    refresh_token_if_expired!
    @xero_client = XeroRuby::ApiClient.new(credentials: xero_credentials)
  end

  def get_connections
    refresh_token_if_expired!
    
    # Use direct HTTP call to get connections
    uri = URI('https://api.xero.com/connections')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Failed to get Xero connections: #{e.message}"
    []
  end

  def get_accounts
    refresh_token_if_expired!
    
    Rails.logger.info "Fetching accounts for tenant: #{@user.xero_tenant_id}"
    
    # Use direct HTTP call with proper headers - ONLY get BANK accounts for payment sync
    uri = URI('https://api.xero.com/api.xro/2.0/Accounts')
    uri.query = URI.encode_www_form(where: 'Status=="ACTIVE"&&Type=="BANK"')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Xero-Tenant-Id'] = @user.xero_tenant_id
    
    response = http.request(request)
    
    if response.code.to_i == 401
      Rails.logger.error "Xero API returned 401 - attempting token refresh"
      refresh_token_if_expired!(force: true)
      # Retry with new token
      request['Authorization'] = "Bearer #{@user.xero_access_token}"
      response = http.request(request)
    end
    
    if response.code.to_i != 200
      Rails.logger.error "Xero API error: Status: #{response.code}, Body: #{response.body}"
      raise "Failed to fetch accounts from Xero: #{response.code}"
    end
    
    data = JSON.parse(response.body)
    accounts = data['Accounts'] || []
    
    # Return only BANK accounts for payment recording
    accounts.map do |account|
      {
        code: account['Code'],
        name: account['Name'],
        type: account['Type'],
        status: account['Status'],
        description: account['Description'],
        account_id: account['AccountID']
      }
    end.select { |acc| acc[:status] == 'ACTIVE' && acc[:type] == 'BANK' }
  rescue => e
    Rails.logger.error "Failed to fetch Xero accounts: #{e.class.name}: #{e.message}"
    raise
  end

  def create_payment(sale)
    return unless @user.xero_tenant_id.present? && sale.sale_type&.sync_to_xero?
    
    refresh_token_if_expired!
    
    # Create a simple sales receipt
    contact = find_or_create_cash_sale_contact
    
    # Step 1: Create the invoice
    invoice_data = {
      "Type" => "ACCREC",
      "Contact" => { "ContactID" => contact['ContactID'] },
      "Date" => sale.sale_date&.to_s || Date.current.to_s,
      "DueDate" => sale.sale_date&.to_s || Date.current.to_s,
      "Status" => "AUTHORISED",
      "LineAmountTypes" => "Exclusive",
      "LineItems" => build_line_items_for_sale(sale)
    }
    
    uri = URI('https://api.xero.com/api.xro/2.0/Invoices')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Xero-Tenant-Id'] = @user.xero_tenant_id
    request.body = { "Invoices" => [invoice_data] }.to_json
    
    response = http.request(request)
    
    if response.code.to_i != 200
      Rails.logger.error "Failed to create Xero invoice: Status: #{response.code}, Body: #{response.body}"
      raise "Failed to create invoice in Xero: #{response.code}"
    end
    
    invoice_result = JSON.parse(response.body)
    invoice = invoice_result['Invoices']&.first
    
    return unless invoice && invoice['InvoiceID']
    
    # Step 2: Create the payment
    payment_data = {
      "Invoice" => { "InvoiceID" => invoice['InvoiceID'] },
      "Account" => { "Code" => sale.sale_type.xero_account_code },
      "Date" => sale.sale_date&.to_s || Date.current.to_s,
      "Amount" => sale.total_received.to_f
    }
    
    uri = URI('https://api.xero.com/api.xro/2.0/Payments')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Xero-Tenant-Id'] = @user.xero_tenant_id
    request.body = { "Payments" => [payment_data] }.to_json
    
    response = http.request(request)
    
    if response.code.to_i != 200
      Rails.logger.error "Failed to create Xero payment: Status: #{response.code}, Body: #{response.body}"
      # Don't raise here - invoice was created successfully, just log the payment failure
      Rails.logger.warn "Invoice created but payment failed for sale #{sale.id}"
    else
      Rails.logger.info "Successfully synced sale #{sale.id} to Xero with payment"
    end
    
    invoice
  rescue => e
    Rails.logger.error "Failed to sync sale to Xero: #{e.message}"
    raise
  end
  
  private
  
  def build_line_items_for_sale(sale)
    # Always use a single generic line item
    [{
      "Description" => "Consult/Herbal Product Fees",
      "Quantity" => 1.0,
      "UnitAmount" => sale.total_received.to_f,
      "AccountCode" => "200" # Default sales account
    }]
  end

  private

  def xero_credentials
    {
      client_id: Rails.application.credentials.xero[:client_id],
      client_secret: Rails.application.credentials.xero[:client_secret],
      grant_type: 'authorization_code',
      access_token: @user.xero_access_token,
      token_set: {
        access_token: @user.xero_access_token,
        refresh_token: @user.xero_refresh_token,
        expires_at: @user.xero_token_expires_at&.to_i
      }
    }
  end

  def refresh_token_if_expired!(force: false)
    return if @user.xero_token_expires_at.nil? && !force
    return if !force && @user.xero_token_expires_at > Time.current + 5.minutes
    
    Rails.logger.info "Refreshing Xero token (force: #{force})"
    
    client_id = Rails.application.credentials.xero[:client_id]
    client_secret = Rails.application.credentials.xero[:client_secret]
    
    # Use Basic Auth as per your other app's implementation
    uri = URI('https://identity.xero.com/connect/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(client_id, client_secret)
    request.set_form_data(
      'grant_type' => 'refresh_token',
      'refresh_token' => @user.xero_refresh_token
    )
    
    response = http.request(request)
    token_data = JSON.parse(response.body)
    
    if token_data['error']
      Rails.logger.error "Failed to refresh Xero token: #{token_data['error_description']}"
      raise "Failed to refresh Xero token: #{token_data['error_description']}"
    end
    
    @user.update!(
      xero_access_token: token_data['access_token'],
      xero_refresh_token: token_data['refresh_token'],
      xero_token_expires_at: Time.current + token_data['expires_in'].to_i.seconds
    )
    
    Rails.logger.info "Successfully refreshed Xero token"
    
    # Recreate the client with new credentials if it exists
    if @xero_client
      @xero_client = XeroRuby::ApiClient.new(credentials: xero_credentials)
    end
  end

  def find_or_create_cash_sale_contact
    # First try to find existing "Cash Sale" contact
    uri = URI('https://api.xero.com/api.xro/2.0/Contacts')
    uri.query = URI.encode_www_form(where: 'Name=="Cash Sale"')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Xero-Tenant-Id'] = @user.xero_tenant_id
    
    response = http.request(request)
    
    if response.code.to_i == 200
      data = JSON.parse(response.body)
      contacts = data['Contacts'] || []
      
      if contacts.any?
        return contacts.first
      end
    end
    
    # Create new "Cash Sale" contact if not found
    contact_data = {
      "Name" => "Cash Sale",
      "ContactStatus" => "ACTIVE"
    }
    
    uri = URI('https://api.xero.com/api.xro/2.0/Contacts')
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@user.xero_access_token}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Xero-Tenant-Id'] = @user.xero_tenant_id
    request.body = { "Contacts" => [contact_data] }.to_json
    
    response = http.request(request)
    
    if response.code.to_i != 200
      Rails.logger.error "Failed to create contact: Status: #{response.code}, Body: #{response.body}"
      raise "Failed to create contact in Xero"
    end
    
    result = JSON.parse(response.body)
    result['Contacts']&.first
  end
end