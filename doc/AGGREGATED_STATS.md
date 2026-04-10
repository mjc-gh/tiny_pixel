# Aggregated Stats Models

tiny_pixel aggregates page analytics into three time-based models sharing the same structure:

| Model | Time Column | Granularity |
|-------|-------------|-------------|
| `HourlyPageStat` | `time_bucket` (datetime) | Per hour |
| `DailyPageStat` | `date` (date) | Per day |
| `WeeklyPageStat` | `week_start` (date) | Per week |

## Fields

**Unique key**: `(site_id, hostname, pathname, dimension_type, dimension_value, time_column)`

### Dimensions

| Column | Type | Description |
|--------|------|-------------|
| `site_id` | FK | Foreign key to site |
| `hostname` | string | Page hostname |
| `pathname` | string | Page path |
| `dimension_type` | string (not null) | `"global"`, `"country"`, `"browser"`, `"device_type"`, `"referrer_hostname"` |
| `dimension_value` | string (nullable) | `nil` for global; otherwise: country code (`"US"`), browser (`"chrome"`), device (`"mobile"`), referrer (`"google.com"`) |

### Metrics

| Metric | Description | Deduplication |
|--------|-------------|---------------|
| `pageviews` | Raw count of every page load | None |
| `unique_pageviews` | First view of pathname per visitor | Per visitor + pathname within salt cycle |
| `visits` | Distinct visitors (new visitor digests) | Per visitor (`new_visit` flag) |
| `sessions` | Activity periods separated by inactivity | Resets after session timeout |
| `bounced_count` | Single-page sessions | — |
| `total_duration` | Sum of time on page (seconds) | — |
| `duration_count` | Pageviews with duration data | — |

**unique_pageviews** deduplication window depends on `salt_duration`:
- **Daily**: 24-hour relative window
- **Weekly**: Calendar week
- **Monthly**: Calendar month

Determined by `is_unique` flag in `PixelRequest#process!`.

**sessions** start when: (1) visitor is new, OR (2) time since last pageview exceeds session timeout. A single visit can span multiple sessions.

## Computed Methods

- `avg_duration` → `total_duration / duration_count` (nil if no data)
- `bounce_rate` → `(bounced_count / pageviews) * 100` (nil if no pageviews)

## Scopes

All three models share identical scopes:

| Scope | Description |
|-------|-------------|
| `for_site(id)` | Filter by site |
| `for_date_range(start, end)` | Filter by time range |
| `for_hostname(hostname)` | Filter by hostname |
| `for_pathname(pathname)` | Filter by pathname |
| `global` | Global stats only (`dimension_type = "global"`) |
| `for_dimension(type, value)` | Specific dimension (e.g., `"country", "US"`) |
| `for_dimension_type(type)` | All values of a dimension type |
| `ordered_by_pageviews` | Order by pageviews desc |
| `ordered_by_time` / `_date` / `_week` | Order by time desc |

## Query Examples

```ruby
HourlyPageStat.for_site(123).global                              # Global stats
HourlyPageStat.for_site(123).for_dimension("country", "US")      # USA stats
HourlyPageStat.for_site(123).for_dimension_type("country")       # All countries
DailyPageStat.for_site(123).global.for_date_range(7.days.ago, Date.today)
```

## Schema Design

Two-column storage for dimensions enables efficient filtering:

```sql
CREATE UNIQUE INDEX idx_hourly_page_stats_unique ON hourly_page_stats
  (site_id, hostname, pathname, dimension_type, dimension_value, time_bucket);
```

**Benefits**: Direct equality queries (`WHERE dimension_type = 'country'`), proper indexing, no string parsing.

## AggregationService

```ruby
service = AggregationService.new(site)

# Single dimension
service.aggregate_hourly(time_bucket, dimension_type: "country")

# All dimensions (primary entry point for production)
service.aggregate_all_dimensions_hourly(time_bucket)
service.aggregate_all_dimensions_daily(date)
service.aggregate_all_dimensions_weekly(week_start)
```

**Supported dimension types**: `"global"`, `"country"`, `"browser"`, `"device_type"`, `"referrer_hostname"`

**Class methods**:
- `AggregationService.dimension_expression_for_type(type)` → SQL column expression
- `AggregationService::SUPPORTED_DIMENSION_TYPES` → list of types

## Adding New Dimensions

### 1. Determine Dimension Type

| Type | Source | Handling |
|------|--------|----------|
| **Visitor-based** (country, browser, device_type) | `visitors` table | Standard SQL grouping via `fetch_raw_stats_standard` |
| **PageView-based** (referrer_hostname) | `page_views` table | Window function to propagate first value; map NULL to default |

### 2. Update `AggregationService`

Add case to `dimension_expression_for_type(type)`:
```ruby
when "my_new_dimension"
  "visitors.my_column"  # or "page_views.column"
```

For pageview-based with missing values: implement `fetch_raw_stats_with_window_function_for_*` using `FIRST_VALUE(NULLIF(column, '')) OVER (PARTITION BY visitor_digest ORDER BY created_at)`.

### 3. Update Models

Add to `SUPPORTED_DIMENSION_TYPES` in `AggregationService`. Scopes work automatically.

### 4. Test

- All three granularities (hourly, daily, weekly)
- Edge cases: NULL values, empty values, defaults
- Verify `aggregate_all_dimensions_*` includes new dimension

### 5. Update Documentation

Add to dimensions list, supported types, and query examples.

**Reference**: PageView-based pattern in commit `6ce7d68` (`app/services/aggregation_service.rb:147-184`)

## Schema Migrations for Dimensions

### Migration Pattern

1. **Add new columns** with defaults
2. **Migrate data** (e.g., parse composite strings with `SUBSTR`/`INSTR`)
3. **Update indexes**: remove old, add new unique index, add filter index on `dimension_type`
4. **Remove old columns**
5. **Update models**

### Testing Migrations

```bash
rails db:migrate:reset        # Verify from scratch
rm -f tmp/schema_cache.db     # Clear schema cache
rails test                    # Full test suite
```
