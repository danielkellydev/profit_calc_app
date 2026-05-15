require 'net/http'
require 'json'
require 'uri'
require 'base64'

class WoocommerceService
  class Error < StandardError; end
  class NotConfiguredError < Error; end
  class AuthenticationError < Error; end
  class StoreUnreachableError < Error; end

  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30

  def initialize(user)
    @user = user
    @config = user.woocommerce_config
    raise NotConfiguredError, 'WooCommerce is not configured for this user.' if @config.nil? || !@config.configured?
  end

  # Returns or refreshes a RevenueSnapshot for a given date range.
  def period_revenue(start_date, end_date, force: false)
    snapshot = @user.revenue_snapshots.find_by(period_start: start_date, period_end: end_date)

    return snapshot if snapshot && !force && !snapshot.stale?

    data = fetch_period_revenue(start_date, end_date)
    snapshot ||= @user.revenue_snapshots.new(period_start: start_date, period_end: end_date)
    snapshot.assign_attributes(
      gross_sales: data[:gross_sales],
      net_sales:   data[:net_sales],
      order_count: data[:order_count],
      fetched_at:  Time.current
    )
    snapshot.save!
    @config.record_success!
    snapshot
  end

  def test_connection
    request_json('/wp-json/wc/v3/system_status')
    @config.record_success!
    true
  end

  private

  attr_reader :config

  def fetch_period_revenue(start_date, end_date)
    begin
      reports_endpoint_revenue(start_date, end_date)
    rescue StoreUnreachableError, AuthenticationError
      raise
    rescue Error
      orders_endpoint_revenue(start_date, end_date)
    end
  end

  def reports_endpoint_revenue(start_date, end_date)
    data = request_json(
      '/wp-json/wc/v3/reports/sales',
      date_min: start_date.iso8601,
      date_max: end_date.iso8601
    )
    row = data.is_a?(Array) ? data.first : data
    raise Error, 'Reports endpoint returned no data' if row.blank?

    {
      gross_sales: BigDecimal(row['total_sales'].to_s.presence || '0'),
      net_sales:   BigDecimal(row['net_sales'].to_s.presence   || row['total_sales'].to_s.presence || '0'),
      order_count: row['total_orders'].to_i
    }
  end

  def orders_endpoint_revenue(start_date, end_date)
    gross = BigDecimal('0')
    net   = BigDecimal('0')
    count = 0
    page = 1

    loop do
      orders = request_json(
        '/wp-json/wc/v3/orders',
        status:   'completed',
        after:    start_date.beginning_of_day.iso8601,
        before:   end_date.end_of_day.iso8601,
        per_page: 100,
        page:     page
      )
      break if orders.blank?

      orders.each do |o|
        gross += BigDecimal(o['total'].to_s.presence || '0')
        net   += BigDecimal(o['total'].to_s.presence || '0') -
                 BigDecimal(o['total_tax'].to_s.presence || '0') -
                 BigDecimal(o['shipping_total'].to_s.presence || '0')
        count += 1
      end

      break if orders.size < 100

      page += 1
      break if page > 50 # safety stop ~5000 orders
    end

    { gross_sales: gross, net_sales: net, order_count: count }
  end

  def request_json(path, query = {})
    uri = URI.join(config.normalized_store_url + '/', path.sub(%r{^/}, ''))
    uri.query = URI.encode_www_form(query) if query.any?

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept'] = 'application/json'
    request['Authorization'] = basic_auth_header

    response = http_client(uri).request(request)
    handle_response(response, uri)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
    raise StoreUnreachableError, "Could not reach WooCommerce store: #{e.message}"
  end

  def basic_auth_header
    encoded = Base64.strict_encode64("#{config.consumer_key}:#{config.consumer_secret}")
    "Basic #{encoded}"
  end

  def http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http
  end

  def handle_response(response, uri)
    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    when 401, 403
      raise AuthenticationError, "WooCommerce rejected credentials (HTTP #{response.code})"
    when 404
      raise Error, "Endpoint not found at #{uri.path} (HTTP 404)"
    else
      raise Error, "WooCommerce returned HTTP #{response.code}: #{response.body.to_s.first(200)}"
    end
  rescue JSON::ParserError
    raise Error, "WooCommerce returned non-JSON response (HTTP #{response.code})"
  end
end
