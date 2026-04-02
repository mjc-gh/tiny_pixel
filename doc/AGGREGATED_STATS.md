# Aggregated Stats Models

tiny_pixel aggregates page analytics into three time-based models: hourly, daily, and weekly. All three share the same structure, differing only in their time granularity.

## Models

| Model | Time Column | Granularity |
|-------|-------------|-------------|
| `HourlyPageStat` | `time_bucket` (datetime) | Per hour |
| `DailyPageStat` | `date` (date) | Per day |
| `WeeklyPageStat` | `week_start` (date) | Per week |

## Common Fields

Each record is uniquely identified by `(site_id, hostname, pathname, time_bucket/date/week_start)`.

### Dimensions
- **site_id** - Foreign key to the site
- **hostname** - The page's hostname
- **pathname** - The page's path

### Metrics

#### Pageviews vs Unique Pageviews vs Visits vs Sessions

These four metrics measure user engagement at different levels:

| Metric | What it counts | Deduplication |
|--------|----------------|---------------|
| **pageviews** | Every page load | None - raw count |
| **unique_pageviews** | First view of a page per visitor | Per visitor + pathname within salt cycle duration |
| **visits** | Distinct visitors arriving at the site | Per visitor (based on `new_visit` flag) |
| **sessions** | Activity periods separated by inactivity | Per visitor, resets after session timeout |

**pageviews** - The raw count of every page load event. If a user refreshes a page 5 times, that's 5 pageviews.

**unique_pageviews** - Counts the first time a visitor views a specific pathname within the site's salt cycle duration. The lookback window depends on the site's `salt_duration` configuration:
- **Daily** (24-hour relative window): If the same visitor views `/about` three times within 24 hours, it counts as 1 unique pageview. Resets after 24 hours have passed.
- **Weekly** (calendar week): If the same visitor views `/about` multiple times within the same calendar week, it counts as 1 unique pageview. Resets on the first day of the week.
- **Monthly** (calendar month): If the same visitor views `/about` multiple times within the same calendar month, it counts as 1 unique pageview. Resets on the first day of the month.

Determined by the `is_unique` flag set in `PixelRequest#process!`.

**visits** - Counts distinct visitors arriving at the site. A visit is recorded when a new visitor digest is inserted (first-time visitor). This represents the number of unique people who visited.

**sessions** - Counts activity periods. A new session starts when:
1. A visitor is completely new (first pageview ever), OR
2. The time since their last pageview exceeds the site's session timeout

A single visit can span multiple sessions if the user is inactive and returns later.

#### Other Metrics
- **bounced_count** - Number of single-page sessions (visitor left without viewing another page)
- **total_duration** - Sum of time spent on page (seconds), calculated from time between pageviews
- **duration_count** - Number of pageviews with duration data (used to calculate average)

## Computed Methods

- `avg_duration` - Returns `total_duration / duration_count` (nil if no duration data)
- `bounce_rate` - Returns `(bounced_count / pageviews) * 100` as a percentage (nil if no pageviews)

## Available Scopes

All three models provide identical scopes:
- `for_site(site_id)` - Filter by site
- `for_date_range(start, end)` - Filter by time range
- `for_hostname(hostname)` - Filter by hostname
- `for_pathname(pathname)` - Filter by pathname
- `ordered_by_pageviews` - Order by pageviews descending
- `ordered_by_time` / `ordered_by_date` / `ordered_by_week` - Order by time descending
