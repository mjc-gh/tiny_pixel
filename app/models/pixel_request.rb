# frozen_string_literal: true

class PixelRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  # attribute :origin, :string
  attribute :property_id, :string
  attribute :remote_ip, :string
  attribute :user_agent, :string
  attribute :hostname, :string
  attribute :pathname, :string
  attribute :attribution, :string
  attribute :referrer, :string

  # TODO: add :origin?
  validates :hostname, :pathname, :property_id, :remote_ip, :user_agent, presence: true
  validate :property_must_exist

  DEFAULT_COUNTRY_CODE = ""

  # Instantiate the parser on load as it's quite expensive
  USER_AGENT_PARSER = UserAgentParser::Parser.new

  UNIQUE_WINDOW = 24.hours

  def self.from_incoming(request, params)
    new.tap do |instance|
      instance.assign_attributes(
        # origin: request.origin,
        property_id: params[:pid].to_s,
        hostname: params[:h],
        pathname: params[:p],
        attribution: params[:qs],
        referrer: params[:r],
        remote_ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end
  end

  def initialize
    super
    @created_at = Time.current
    @new_visit = false
    @new_session = false
    @is_unique = false
  end

  def process!
    return unless valid?

    result = Visitor.insert(visitor_attributes, returning: %i[digest])

    if result.rows.any?
      @new_visit = true
      @new_session = true
    else
      previous_pageview = find_previous_pageview
      in_same_session = previous_pageview.present? &&
        (@created_at - previous_pageview.created_at) <= property.session_timeout

      if in_same_session
        update_previous_pageview_duration(previous_pageview)
        update_session_pageviews_as_not_bounced(previous_pageview)
      else
        @new_session = true
      end
    end

    @is_unique = !PageView.exists?(visitor_digest:, pathname:, created_at: UNIQUE_WINDOW.ago..)

    PageView.insert page_view_attributes

    nil
  end

  private

  def visitor_attributes
    { digest: visitor_digest,
      property_id: property.id,
      browser: visitor_browser,
      device_type: visitor_device_type,
      country: visitor_country }
  end

  def page_view_attributes
    { visitor_digest:,
      digest: page_view_digest,
      created_at: @created_at,
      hostname:,
      pathname:,
      new_visit: @new_visit,
      new_session: @new_session,
      is_unique: @is_unique,
      attribution:,
      referrer:,
      referrer_hostname: parsed_referrer[:hostname],
      referrer_pathname: parsed_referrer[:pathname] }
  end

  def property
    @property ||= SiteCache[property_id]
  end

  def visitor_browser
    browser = parsed_user_agent.family.downcase
    browser.delete_suffix! " mobile"
    browser.delete_prefix! "mobile "

    return browser if browser.in? Visitor.browsers

    "other"
  end

  def visitor_country
    geo = TinyPixel.maxmind_db.get(remote_ip)

    TinyPixel.research_log.info "Geo: #{geo.inspect}"

    geo&.dig("country", "iso_code") || DEFAULT_COUNTRY_CODE
  rescue IPAddr::Error
    DEFAULT_COUNTRY_CODE
  end

  def visitor_device_type
    return "crawler" if parsed_user_agent.device.family.downcase == "spider"

    case parsed_user_agent.os.family.downcase
    when /android/, /iphone/, /ios/ then "mobile"
    when /windows/, /linux/, /mac/  then "desktop"
    else "other"
    end
  end

  def visitor_digest
    return @visitor_digest unless @visitor_digest.nil?

    digest = sha_256 do |d|
      d << property.salt
      d << remote_ip
      d << user_agent
      d << hostname
    end

    @visitor_digest ||= digest.hexdigest
  end

  def page_view_digest
    return @page_view_digest unless @page_view_digest.nil?

    digest = sha_256 do |d|
      d << visitor_digest
      d << pathname
    end

    @page_view_digest ||= digest.hexdigest
  end

  def property_must_exist
    errors.add :property_id, :unknown if property.nil?
  end

  def find_previous_pageview
    PageView
      .where(visitor_digest:)
      .order(created_at: :desc)
      .limit(1)
      .first
  end

  def update_previous_pageview_duration(previous_pageview)
    duration = (@created_at - previous_pageview.created_at).to_i

    PageView.where(
      visitor_digest:,
      created_at: previous_pageview.created_at
    ).update_all(duration:)
  end

  def update_session_pageviews_as_not_bounced(reference_pageview)
    session_start = reference_pageview.created_at - property.session_timeout

    PageView.where(
      visitor_digest:,
      created_at: session_start..reference_pageview.created_at
    ).update_all(bounced: false)
  end

  def parsed_referrer
    @parsed_referrer ||= ReferrerParser.parse(referrer)
  end

  def parsed_user_agent
    @parsed_user_agent ||= USER_AGENT_PARSER.parse(user_agent).tap do |p|
      TinyPixel.research_log.info "User-agent: #{user_agent.inspect}"
      TinyPixel.research_log.info "User-agent Results: #{p.to_h.inspect}"
    end
  end

  def sha_256(&block)
    Digest::SHA256.new.tap(&block)
  end
end
