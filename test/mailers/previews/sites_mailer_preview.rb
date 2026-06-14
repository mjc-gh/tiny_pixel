# frozen_string_literal: true

class SitesMailerPreview < ActionMailer::Preview
  def weekly_summary
    user = User.first || User.new(email: "preview@example.com")

    # Build sample data for preview
    sites_data = [
      {
        site: Site.new(name: "My Blog"),
        avg_daily_pageviews: 156.4,
        avg_daily_sessions: 48.7,
        avg_daily_duration: 185.3,
        top_page_by_sessions: {
          pathname: "/blog/getting-started",
          sessions: 542
        },
        top_page_by_duration: {
          pathname: "/docs/guide",
          avg_duration: 325.8
        }
      },
      {
        site: Site.new(name: "SaaS Product"),
        avg_daily_pageviews: 289.1,
        avg_daily_sessions: 92.3,
        avg_daily_duration: 142.5,
        top_page_by_sessions: {
          pathname: "/app/dashboard",
          sessions: 823
        },
        top_page_by_duration: {
          pathname: "/app/settings",
          avg_duration: 298.4
        }
      }
    ]

    SitesMailer.weekly_summary(user, sites_data)
  end
end
