class ApplicationController < ActionController::Base
  before_action :set_time_zone

  private

  def set_time_zone
    ip = Rails.env.development? ? '128.250.204.118' : request.remote_ip
    location = Geocoder.search(ip).first
    if location && location.latitude && location.longitude
      time_zone = Timezone.lookup(location.latitude, location.longitude)
      Time.zone = time_zone.name if time_zone
    end
  end
end