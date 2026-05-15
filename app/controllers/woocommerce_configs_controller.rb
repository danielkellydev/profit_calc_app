class WoocommerceConfigsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @config = current_user.woocommerce_config || current_user.build_woocommerce_config
  end

  def update
    @config = current_user.woocommerce_config || current_user.build_woocommerce_config
    if @config.update(config_params)
      redirect_to settings_path, notice: 'WooCommerce settings saved.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test_connection
    @config = current_user.woocommerce_config
    if @config.nil? || !@config.configured?
      render json: { ok: false, message: 'Save store URL and credentials first.' }, status: :unprocessable_entity
      return
    end

    WoocommerceService.new(current_user).test_connection
    render json: { ok: true, message: 'Connection successful.' }
  rescue WoocommerceService::AuthenticationError => e
    @config.record_failure!('auth_error', e.message)
    render json: { ok: false, message: 'Authentication failed — check consumer key/secret.' }, status: :unauthorized
  rescue WoocommerceService::StoreUnreachableError => e
    @config.record_failure!('unreachable', e.message)
    render json: { ok: false, message: 'Could not reach the store URL.' }, status: :bad_gateway
  rescue WoocommerceService::Error => e
    @config.record_failure!('unreachable', e.message)
    render json: { ok: false, message: e.message }, status: :bad_gateway
  end

  private

  def config_params
    params.require(:woocommerce_config).permit(:store_url, :consumer_key, :consumer_secret)
  end
end
