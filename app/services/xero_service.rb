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
    
    # Use direct HTTP call with proper headers
    uri = URI('https://api.xero.com/api.xro/2.0/Accounts')
    uri.query = URI.encode_www_form(where: 'Status=="ACTIVE"')
    
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
    
    # Group and format accounts similar to your other app
    accounts.map do |account|
      {
        code: account['Code'],
        name: account['Name'],
        type: account['Type'],
        status: account['Status'],
        description: account['Description'],
        account_id: account['AccountID']
      }
    end.select { |acc| acc[:status] == 'ACTIVE' }
  rescue => e
    Rails.logger.error "Failed to fetch Xero accounts: #{e.class.name}: #{e.message}"
    raise
  end

  def create_payment(sale)
    return unless @user.xero_tenant_id.present? && sale.sale_type&.sync_to_xero?
    
    refresh_token_if_expired!
    
    accounting_api = XeroRuby::AccountingApi.new(@xero_client)
    
    # Create a sales invoice first
    contact = find_or_create_contact(accounting_api)
    invoice = create_invoice(accounting_api, sale, contact)
    
    # Then create a payment for that invoice
    payment = XeroRuby::Payment.new(
      invoice: { invoice_id: invoice.invoice_id },
      account: { code: sale.sale_type.xero_account_code },
      date: sale.sale_date || Date.current,
      amount: sale.total_revenue.to_f
    )
    
    payments = XeroRuby::Payments.new(payments: [payment])
    result = accounting_api.create_payment(@user.xero_tenant_id, payments)
    result.payments.first
  rescue => e
    Rails.logger.error "Failed to sync sale to Xero: #{e.message}"
    raise
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

  def find_or_create_contact(api)
    # Use a default "Cash Sale" contact
    contacts = api.get_contacts(@user.xero_tenant_id, where: "Name=\"Cash Sale\"")
    
    if contacts.contacts.any?
      contacts.contacts.first
    else
      contact = XeroRuby::Contact.new(
        name: "Cash Sale",
        contact_status: 'ACTIVE'
      )
      
      contacts_obj = XeroRuby::Contacts.new(contacts: [contact])
      result = api.create_contacts(@user.xero_tenant_id, contacts_obj)
      result.contacts.first
    end
  end

  def create_invoice(api, sale, contact)
    line_items = sale.sale_items.map do |item|
      XeroRuby::LineItem.new(
        description: item.product.name,
        quantity: item.quantity.to_f,
        unit_amount: item.price.to_f,
        account_code: '200' # Default sales account - you may want to make this configurable
      )
    end
    
    # If no sale items, create a single line item
    if line_items.empty?
      line_items = [
        XeroRuby::LineItem.new(
          description: sale.sale_type&.name || "Cash Sale",
          quantity: 1.0,
          unit_amount: sale.total_revenue.to_f,
          account_code: '200'
        )
      ]
    end
    
    invoice = XeroRuby::Invoice.new(
      type: 'ACCREC',
      contact: contact,
      date: sale.sale_date || Date.current,
      due_date: sale.sale_date || Date.current,
      line_items: line_items,
      status: 'AUTHORISED'
    )
    
    invoices = XeroRuby::Invoices.new(invoices: [invoice])
    result = api.create_invoices(@user.xero_tenant_id, invoices)
    result.invoices.first
  end
end