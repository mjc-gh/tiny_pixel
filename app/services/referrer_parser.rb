# frozen_string_literal: true

class ReferrerParser
  def self.parse(referrer_string)
    new(referrer_string).parse
  end

  def initialize(referrer_string)
    @referrer_string = referrer_string.to_s.strip
  end

  def parse
    return { hostname: nil, pathname: nil } if @referrer_string.blank?

    begin
      uri = URI.parse(@referrer_string)

      # If no host is present, treat as malformed URL
      hostname = extract_hostname(uri.host)
      return { hostname: nil, pathname: nil } if hostname.nil?

      {
        hostname:,
        pathname: uri.path.presence || "/"
      }
    rescue URI::InvalidURIError
      # If parsing fails, return nil for both
      { hostname: nil, pathname: nil }
    end
  end

  private

  def extract_hostname(host)
    return nil if host.blank?

    # Remove www. prefix for cleaner aggregation (case-insensitive)
    host.downcase.gsub(/^www\./, "")
  end
end
