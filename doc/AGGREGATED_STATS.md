# Aggregated Stats Models

tiny_pixel aggregates page analytics into three time-based models: hourly, daily, and weekly. All three share the same structure, differing only in their time granularity.

## Models

| Model | Time Column | Granularity |
|-------|-------------|-------------|
| `HourlyPageStat` | `time_bucket` (datetime) | Per hour |
| `DailyPageStat` | `date` (date) | Per day |
| `WeeklyPageStat` | `week_start` (date) | Per week |

## Common Fields

Each record is uniquely identified by `(site_id, hostname, pathname, dimension, time_bucket/date/week_start)`.

### Dimensions
- **site_id** - Foreign key to the site
- **hostname** - The page's hostname
- **pathname** - The page's path
- **dimension** - Aggregation dimension (string, non-nullable, default: `"global"`)
  - `"global"` - Aggregated across all dimension values (default for all records)
  - `"country:<value>"` - Aggregated by country (e.g., `"country:US"`, `"country:GB"`)
  - `"browser:<value>"` - Aggregated by browser (e.g., `"browser:chrome"`, `"browser:firefox"`)
  - `"device_type:<value>"` - Aggregated by device type (e.g., `"device_type:mobile"`, `"device_type:desktop"`)
  - `"referrer_hostname:<value>"` - Aggregated by referrer hostname (e.g., `"referrer_hostname:google.com"`, `"referrer_hostname:direct"`)

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

### Location Scopes
- `for_site(site_id)` - Filter by site
- `for_date_range(start, end)` - Filter by time range
- `for_hostname(hostname)` - Filter by hostname
- `for_pathname(pathname)` - Filter by pathname

### Dimension Scopes
- `global` - Filter to global stats only (dimension = `"global"`)
- `for_dimension(dimension)` - Filter by specific dimension (e.g., `for_dimension("country:US")`)
- `for_dimension_type(type)` - Filter by dimension type (e.g., `for_dimension_type("country")` returns all `country:*` records)

### Ordering Scopes
- `ordered_by_pageviews` - Order by pageviews descending
- `ordered_by_time` / `ordered_by_date` / `ordered_by_week` - Order by time descending

## Querying Examples

### Get global stats for a site
```ruby
HourlyPageStat.for_site(123).global
```

### Get country-specific stats
```ruby
HourlyPageStat.for_site(123).for_dimension("country:US")
```

### Get all country breakdowns
```ruby
HourlyPageStat.for_site(123).for_dimension_type("country")
```

### Get stats by specific time period
```ruby
DailyPageStat.for_site(123).global.for_date_range(Date.today - 7.days, Date.today)
```

### Get referrer-specific stats
```ruby
HourlyPageStat.for_site(123).for_dimension("referrer_hostname:google.com")
```

### Get all referrer breakdowns
```ruby
HourlyPageStat.for_site(123).for_dimension_type("referrer_hostname")
```

## Dimension Format

Dimensions use a hierarchical string format to support flexible aggregation dimensions:
- **Type prefix** (before colon): `country`, `browser`, `device_type`, or `global`
- **Value** (after colon): The specific value for that dimension type

This format allows:
- Easy filtering: `WHERE dimension LIKE 'country:%'` matches all country breakdowns
- Type safety: Parse the prefix to validate dimension types
- Future extensibility: Add new dimension types without schema changes
- Simple default: All records default to `"global"` for backward compatibility

## Aggregation Service

The `AggregationService` supports dimension-based aggregation:

### Basic Aggregation (Global Stats)
```ruby
AggregationService.aggregate_hourly_for_site(site, time_bucket)
```

### Dimension-Specific Aggregation
```ruby
service = AggregationService.new(site)
service.aggregate_hourly(time_bucket, dimension: "country:US")
```

Supported dimension types:
- `"global"` - Aggregates across all dimension values (default)
- `"country:<value>"` - Groups by visitor country
- `"browser:<value>"` - Groups by visitor browser
- `"device_type:<value>"` - Groups by visitor device type
- `"referrer_hostname:<value>"` - Groups by external referrer source hostname

### Class Methods for Dimension Handling

- `AggregationService.dimension_expression_for_type(type)` - Returns SQL column expression for dimension type
- `AggregationService.format_dimension_value(dimension, raw_value)` - Formats dimension value for storage
