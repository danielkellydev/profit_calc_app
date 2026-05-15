class WoocommerceConfig < ApplicationRecord
  belongs_to :user

  encrypts :consumer_key
  encrypts :consumer_secret

  validates :store_url, presence: true, format: { with: %r{\Ahttps?://}i, message: 'must start with http:// or https://' }
  validates :consumer_key, presence: true
  validates :consumer_secret, presence: true

  STATUSES = %w[ok auth_error unreachable].freeze

  def normalized_store_url
    store_url.to_s.sub(%r{/+\z}, '')
  end

  def configured?
    store_url.present? && consumer_key.present? && consumer_secret.present?
  end

  def record_success!
    update!(last_synced_at: Time.current, last_sync_status: 'ok', last_sync_error: nil)
  end

  def record_failure!(status, message)
    update!(last_sync_status: status, last_sync_error: message)
  end
end
