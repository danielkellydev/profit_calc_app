require 'net/http'
require 'json'

class XeroController < ApplicationController
  before_action :authenticate_user!

  def connect
    redirect_to xero_authorization_url, allow_other_host: true
  end

  def callback
    if params[:code].present?
      begin
        token_response = fetch_access_token(params[:code])
        
        current_user.update!(
          xero_access_token: token_response['access_token'],
          xero_refresh_token: token_response['refresh_token'],
          xero_token_expires_at: Time.current + token_response['expires_in'].to_i.seconds
        )
        
        # Fetch and store tenant ID
        xero_service = XeroService.new(current_user)
        connections = xero_service.get_connections
        if connections.any?
          current_user.update!(xero_tenant_id: connections.first['tenantId'])
        end
        
        redirect_to settings_path, notice: "Successfully connected to Xero!"
      rescue => e
        Rails.logger.error "Xero OAuth error: #{e.message}"
        redirect_to settings_path, alert: "Failed to connect to Xero"
      end
    else
      redirect_to settings_path, alert: "Authorization cancelled or failed"
    end
  end

  def disconnect
    current_user.update!(
      xero_access_token: nil,
      xero_refresh_token: nil,
      xero_token_expires_at: nil,
      xero_tenant_id: nil
    )
    redirect_to settings_path, notice: "Disconnected from Xero"
  end

  def fetch_accounts
    return render json: { error: "Not connected to Xero" }, status: :unauthorized unless current_user.xero_access_token.present?
    
    begin
      xero_service = XeroService.new(current_user)
      accounts = xero_service.get_accounts
      render json: accounts
    rescue => e
      Rails.logger.error "Failed to fetch Xero accounts: #{e.message}"
      render json: { error: "Failed to fetch accounts" }, status: :internal_server_error
    end
  end

  private

  def xero_authorization_url
    client_id = Rails.application.credentials.xero[:client_id]
    redirect_uri = Rails.application.credentials.xero[:redirect_uri]
    scope = "accounting.transactions accounting.settings offline_access"
    
    "https://login.xero.com/identity/connect/authorize?" + {
      response_type: 'code',
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: scope,
      state: SecureRandom.hex(16)
    }.to_query
  end

  def fetch_access_token(code)
    client_id = Rails.application.credentials.xero[:client_id]
    client_secret = Rails.application.credentials.xero[:client_secret]
    redirect_uri = Rails.application.credentials.xero[:redirect_uri]
    
    response = Net::HTTP.post_form(
      URI('https://identity.xero.com/connect/token'),
      grant_type: 'authorization_code',
      client_id: client_id,
      client_secret: client_secret,
      code: code,
      redirect_uri: redirect_uri
    )
    
    JSON.parse(response.body)
  end
end