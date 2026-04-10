# Aggregated Stats Models

tiny_pixel aggregates page analytics into three time-based models: hourly, daily, and weekly. All three share the same structure, differing only in their time granularity.

## Models

| Model | Time Column | Granularity |
|-------|-------------|-------------|
| `HourlyPageStat` | `time_bucket` (datetime) | Per hour |
| `DailyPageStat` | `date` (date) | Per day |
| `WeeklyPageStat` | `week_start` (date) | Per week |

## Common Fields

Each record is uniquely identified by `(site_id, hostname, pathname, dimension_type, dimension_value, time_bucket/date/week_start)`.

### Dimensions
- **site_id** - Foreign key to the site
- **hostname** - The page's hostname
- **pathname** - The page's path
- **dimension_type** - Aggregation dimension type (string, non-nullable, default: `"global"`)
  - `"global"` - Aggregated across all dimension values (default for all records)
  - `"country"` - Aggregated by country
  - `"browser"` - Aggregated by browser
  - `"device_type"` - Aggregated by device type
  - `"referrer_hostname"` - Aggregated by referrer hostname
- **dimension_value** - The specific value for the dimension type (string, nullable)
  - `nil` for `dimension_type: "global"`
  - Country codes for `dimension_type: "country"` (e.g., `"US"`, `"GB"`)
  - Browser names for `dimension_type: "browser"` (e.g., `"chrome"`, `"firefox"`)
  - Device types for `dimension_type: "device_type"` (e.g., `"mobile"`, `"desktop"`)
  - Hostnames for `dimension_type: "referrer_hostname"` (e.g., `"google.com"`, `"direct"`)

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
- `global` - Filter to global stats only (dimension_type = `"global"`)
- `for_dimension(type, value)` - Filter by specific dimension type and value (e.g., `for_dimension("country", "US")`)
- `for_dimension_type(type)` - Filter by dimension type (e.g., `for_dimension_type("country")` returns all records with dimension_type = `"country"`)

### Ordering Scopes
- `ordered_by_pageviews` - Order by pageviews descending
- `ordered_by_time` / `ordered_by_date` / `ordered_by_week` - Order by time descending

## Querying Examples

### Get global stats for a site
```ruby
HourlyPageStat.for_site(123).global
```

### Get country-specific stats (USA)
```ruby
HourlyPageStat.for_site(123).for_dimension("country", "US")
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
HourlyPageStat.for_site(123).for_dimension("referrer_hostname", "google.com")
```

### Get all referrer breakdowns
```ruby
HourlyPageStat.for_site(123).for_dimension_type("referrer_hostname")
```

## Schema Design

Dimensions are now stored in two separate columns for proper filtering and indexing:

### Before (Legacy)
```sql
CREATE UNIQUE INDEX idx_hourly_page_stats_unique ON hourly_page_stats
  (site_id, hostname, pathname, dimension, time_bucket);
```
- Single column stored composite values: `"global"`, `"country:US"`, `"browser:chrome"`
- Required string parsing: `dimension.split(":")`
- LIKE queries for type filtering: `WHERE dimension LIKE 'country:%'`

### After (Current)
```sql
CREATE UNIQUE INDEX idx_hourly_page_stats_unique ON hourly_page_stats
  (site_id, hostname, pathname, dimension_type, dimension_value, time_bucket);
```
- Two separate columns for type and value
- Direct equality queries: `WHERE dimension_type = 'country'`
- Proper indexing on `dimension_type` for efficient filtering
- `dimension_value = nil` for global stats

## Aggregation Service

The `AggregationService` supports dimension-based aggregation. It includes helper methods to aggregate all supported dimensions automatically.

### Basic Aggregation (Global Stats Only)
```ruby
service = AggregationService.new(site)
service.aggregate_hourly(time_bucket, dimension_type: "global")
```

### Dimension-Specific Aggregation
```ruby
service = AggregationService.new(site)
service.aggregate_hourly(time_bucket, dimension_type: "country")
```

### Aggregate All Dimensions at Once
```ruby
service = AggregationService.new(site)
# Aggregates global + country + browser + device_type + referrer_hostname
service.aggregate_all_dimensions_hourly(time_bucket)
service.aggregate_all_dimensions_daily(date)
service.aggregate_all_dimensions_weekly(week_start)
```

### Supported Dimension Types
- `"global"` - Aggregates across all dimension values (default)
- `"country"` - Groups by visitor country
- `"browser"` - Groups by visitor browser
- `"device_type"` - Groups by visitor device type
- `"referrer_hostname"` - Groups by external referrer source hostname

### Class Methods for Dimension Handling

- `AggregationService.dimension_expression_for_type(type)` - Returns SQL column expression for dimension type
- `AggregationService.SUPPORTED_DIMENSION_TYPES` - List of supported dimension types

## Dimension Pattern & Architecture

### Two-Column Storage Pattern

tiny_pixel uses a two-column storage pattern for dimensions to enable clean, efficient queries:

- **`dimension_type`** (string, not null): The dimension category (`"global"`, `"country"`, `"browser"`, `"device_type"`, `"referrer_hostname"`)
- **`dimension_value`** (string, nullable): The specific value (`nil` for `"global"`, or the actual value like `"US"`, `"chrome"`)

**Benefits over single composite column:**
- Direct equality queries: `WHERE dimension_type = 'country'` instead of `LIKE 'country:%'`
- Proper database indexing on `dimension_type` for filtering performance
- Type safety: No string parsing required
- Unique constraints include both columns: `(site_id, hostname, pathname, dimension_type, dimension_value, time_bucket)`

### Scope Signature Pattern

All dimension scopes follow a consistent pattern:

```ruby
# Filter by specific type+value pair (most specific)
scope.for_dimension("country", "US")

# Filter by all values of a type (less specific)
scope.for_dimension_type("country")

# Filter to global stats only (special case)
scope.global  # equivalent to for_dimension_type("global")
```

These scopes support chaining with other scopes (e.g., `for_site`, `for_date_range`, `for_pathname`).

### Aggregation Methods

The `AggregationService` provides methods at multiple levels of specificity:

```ruby
service = AggregationService.new(site)

# Aggregate a specific dimension type with all its values
service.aggregate_hourly(time_bucket, dimension_type: "country")

# Aggregate all supported dimension types at once
service.aggregate_all_dimensions_hourly(time_bucket)  # global + country + browser + device_type + referrer_hostname
```

The `aggregate_all_dimensions_*` methods are the primary entry points for production use, as they ensure complete dimension coverage.

## Adding New Dimensions

To add a new aggregation dimension, follow this implementation checklist:

### 1. Determine Dimension Type

Decide whether the dimension value comes from the `visitors` table (visitor-based) or `page_views` table (pageview-based):

**Visitor-based** (country, browser, device_type):
- Value is stored on every page view via the `visitors` table
- Uses standard SQL grouping in `fetch_raw_stats_standard`
- No special handling needed for missing values

**PageView-based** (referrer_hostname):
- Value may be missing on some page views (e.g., internal navigation)
- Requires propagating first value across all page views in a visit
- Use `fetch_raw_stats_with_window_function` with a CTE and `FIRST_VALUE` window function
- Map NULL values to a default (e.g., `'direct'` for referrers without a referrer_hostname)

### 2. Update `AggregationService`

1. Add case to `dimension_expression_for_type(type)`:
   ```ruby
   when "my_new_dimension"
     "visitors.my_column"  # or "page_views.column" for pageview-based
   ```

2. If visitor-based: No additional changes needed, standard implementation handles it automatically

3. If pageview-based with missing values:
   - Implement `fetch_raw_stats_with_window_function_for_my_dimension(start_time, end_time, dimension_expression)` method
   - Use window function to propagate the first non-NULL value: `FIRST_VALUE(NULLIF(column, '')) OVER (PARTITION BY visitor_digest ORDER BY created_at)`
   - Map NULL results to a sensible default

### 3. Update Models

1. Add to `SUPPORTED_DIMENSION_TYPES` constant in `AggregationService`
2. Dimensions are automatically handled by existing scopes (`for_dimension`, `for_dimension_type`)

### 4. Add Comprehensive Tests

- Create test helper method to generate sample data with the new dimension
- Test all three granularities: hourly, daily, weekly
  ```ruby
  result = @service.aggregate_hourly(@time_bucket, dimension_type: "my_new_dimension")
  stat = HourlyPageStat.find_by(dimension_type: "my_new_dimension", dimension_value: "expected_value")
  assert_not_nil stat
  ```
- Test that aggregation includes all related rows (especially for pageview-based dimensions)
- Test edge cases: NULL values, empty values, defaults
- Test the `aggregate_all_dimensions_hourly` method includes your new dimension

### 5. Update Documentation

- Add dimension to the dimensions list with format examples (line 21-32)
- Add to `SUPPORTED_DIMENSION_TYPES` section (line 173-178)
- Add query examples showing how to retrieve this dimension (add after line 122)
- Update this section if your dimension has special considerations

### Example Implementation References

- **Visitor-based (country)**: Standard pattern, minimal code needed
- **PageView-based (referrer_hostname)**: See commit `6ce7d68`
  - Window function: `app/services/aggregation_service.rb` lines 147-184
  - Tests: `test/services/aggregation_service_test.rb` - referrer_hostname tests
  - Complex aggregation handling: all page views in a visit get the first page's referrer

## Database Schema Migrations for Dimensions

When modifying the dimension storage strategy:

### Migration Pattern

1. **Add new columns** with sensible defaults
2. **Data migration**: Parse and transform existing data
   ```ruby
   # For composite string parsing:
   execute(<<~SQL)
     UPDATE table_name
     SET new_column_type = SUBSTR(old_column, 1, INSTR(old_column, ':') - 1),
         new_column_value = SUBSTR(old_column, INSTR(old_column, ':') + 1)
     WHERE old_column LIKE '%:%'
   SQL
   ```
3. **Update indexes**:
   - Remove old unique indexes before dropping columns
   - Add new unique indexes with new column structure
   - Add separate index on frequently-filtered columns (e.g., `dimension_type`)
4. **Remove old columns** after data migration complete
5. **Update models** to reflect new schema

### Testing Migrations

- Run `db:migrate:reset` to verify migration works from scratch
- Test in both development and test environments
- Clear Rails schema cache: `rm -f tmp/schema_cache.db`
- Verify all records migrated: `HourlyPageStat.count` before/after
- Run full test suite after migration: `rails test`
