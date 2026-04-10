# Stat Filtering Pattern

tiny_pixel implements a consistent filtering pattern across all stat display controllers. This pattern allows users to filter dashboard charts by pathname, hostname (when enabled), and date range.

## Overview

The filtering system works through a three-layer pipeline:

1. **Frontend (Stimulus + Components)** - User selects filters via UI (table clicks, date inputs)
2. **URL Parameters** - Stimulus updates turbo-frame URLs with query params
3. **Backend (Controllers)** - Controllers filter database queries based on params

Supported filters:
- **Pathname** - Filter by page path (e.g., `/`, `/about`)
- **Hostname** - Filter by domain (when `display_hostname: true` on site)
- **Date Range** - Filter by start and end dates using HTML5 date inputs

## Architecture

### Frontend: Stimulus Filter Controller

**File:** `app/javascript/controllers/pathname_filter_controller.js`

The Stimulus controller manages user interactions and URL updates:

- **selectPathname()** - Called when user clicks a pathname row
  - Extracts `pathname` and `hostname` from row `data-*` attributes
  - Updates frame URLs with both values as query parameters
  - Shows filter indicator displaying active filter

- **updateDateRange()** - Called when user changes date inputs
  - Extracts `startDate` and `endDate` from date input values
  - Updates frame URLs with both values as query parameters
  - Updates browser URL with Turbo.visit

- **clearFilter()** - Resets all filters
  - Clears pathname and hostname values
  - Updates frame URLs to remove filter parameters
  - Hides filter indicator

- **updateFrameSources()** - Updates all turbo-frame URLs
  - Builds query string: `?interval=daily&pathname=...&hostname=...&start_date=...&end_date=...`
  - Updates all stat chart frames: page_views, visitors, avg_duration, bounce_rate, pathname_stats

- **updateBrowserURL()** - Updates browser URL with current filters
  - Persists filters in query parameters for URL sharing and page refresh

### Backend: IntervalStats Concern

**File:** `app/controllers/concerns/interval_stats.rb`

Provides filter helper methods available to all stat controllers:

```ruby
helper_method :current_interval, :current_pathname, :current_hostname, :stats_time_column,
              :current_start_date, :current_end_date

def current_pathname
  @current_pathname ||= params[:pathname]
end

def current_hostname
  @current_hostname ||= params[:hostname]
end

def current_start_date
  @current_start_date ||= parse_date_param(:start_date)
end

def current_end_date
  @current_end_date ||= parse_date_param(:end_date)
end

def apply_date_range_filter(scope)
  return scope unless current_start_date && current_end_date
  scope.for_date_range(current_start_date, current_end_date)
end

private

def parse_date_param(param_name)
  return nil if params[param_name].blank?
  Date.parse(params[param_name])
rescue Date::Error
  nil
end
```

### Backend: Stat Controllers

All stat controllers (`PageViewsController`, `VisitorsController`, `AvgDurationController`, `BounceRateController`, `PathnamesController`) follow the same filtering pattern:

```ruby
def index
  scope = stats_model.for_site(@site.id)
  scope = scope.for_pathname(current_pathname) if current_pathname.present?
  scope = scope.where(hostname: current_hostname) if current_hostname.present?
  scope = apply_date_range_filter(scope)  # New date range filter
  
  @chart_data = {
    "Page Views" => scope.group(stats_time_column).sum(:pageviews),
    "Unique Page Views" => scope.group(stats_time_column).sum(:unique_pageviews)
  }
end
```

**Date Range Filtering Notes:**
- All three stat models (`HourlyPageStat`, `DailyPageStat`, `WeeklyPageStat`) have a `for_date_range` scope
- The scope accepts `start_date` and `end_date` parameters
- For hourly stats, dates are converted to time_bucket datetime comparison
- For daily/weekly stats, dates are matched directly
- Invalid date formats are handled gracefully (parsed with `Date.parse`, returns nil on error)

## When Hostname Filtering is Available

Hostname filtering is only enabled when a site has `display_hostname: true`. The pathname summary component conditionally renders the hostname column and includes `data-hostname` attributes on table rows.

**Files involved:**
- `PathnameSummaryComponent` - Conditionally renders hostname column
- `PathnamesController` - Groups stats by hostname+pathname when display_hostname is true
- `sites/show.html.erb` - Passes hostname parameter to all stat frames

## Date Range Filtering

Date range filtering is always available on the dashboard. Users can select a start date and end date using HTML5 date inputs.

**Frontend Components:**
- `DateRangeSelectorComponent` - Renders two HTML5 date input fields with Stimulus bindings
- `app/views/sites/show.html.erb` - Renders the date selector component in the dashboard header
- `IntervalSelectorComponent` - Updated to preserve date params when switching intervals

**Backend Integration:**
- `IntervalStats` concern - Provides `current_start_date`, `current_end_date`, and `apply_date_range_filter` helpers
- All stat controllers - Apply `apply_date_range_filter` to their query scopes
- Stat models - Have `for_date_range` scopes defined for each interval type

**URL Parameter:** `start_date` and `end_date` (ISO8601 format: YYYY-MM-DD)

## Adding New Stat Filters

To add a new filterable dimension:

1. **Add a param accessor** to `IntervalStats` concern:
   ```ruby
   def current_my_dimension
     @current_my_dimension ||= params[:my_dimension]
   end
   ```

2. **Add to helper_method declaration** so it's available in views:
   ```ruby
   helper_method :current_interval, :current_pathname, :current_hostname, :stats_time_column,
                 :current_start_date, :current_end_date, :current_my_dimension
   ```

3. **Update filter logic** in stat controllers:
   ```ruby
   scope = scope.where(my_dimension: current_my_dimension) if current_my_dimension.present?
   ```

4. **Update Stimulus controller** to capture and pass the dimension:
   ```javascript
   const myDimension = event.currentTarget.dataset.myDimension
   const myDimensionParam = myDimension ? `&my_dimension=${encodeURIComponent(myDimension)}` : ""
   ```

5. **Update view URLs** to include the new parameter:
   ```erb
   site_page_views_path(@site, interval: current_interval, my_dimension: current_my_dimension)
   ```

6. **Add data attributes** to table rows or summary components to capture the dimension

## Implementation Checklist for Date Range Filtering

The following files were modified to implement date range filtering (see issue #90):

### Backend
- ✓ `app/controllers/concerns/interval_stats.rb` - Added date helpers and apply method
- ✓ `app/controllers/sites/page_views_controller.rb` - Applied date filter
- ✓ `app/controllers/sites/visitors_controller.rb` - Applied date filter
- ✓ `app/controllers/sites/avg_duration_controller.rb` - Applied date filter
- ✓ `app/controllers/sites/bounce_rate_controller.rb` - Applied date filter
- ✓ `app/controllers/sites/pathnames_controller.rb` - Applied date filter

### Frontend Components
- ✓ `app/components/date_range_selector_component.rb` - New component
- ✓ `app/components/date_range_selector_component.html.erb` - Component template
- ✓ `app/components/interval_selector_component.rb` - Updated to preserve date params
- ✓ `app/javascript/controllers/pathname_filter_controller.js` - Added date support

### Views
- ✓ `app/views/sites/show.html.erb` - Integrated date selector and params

### Tests
- ✓ `test/controllers/sites/page_views_controller_test.rb` - Added date filtering tests
- ✓ `test/controllers/sites/visitors_controller_test.rb` - Added date filtering tests
- ✓ `test/controllers/sites/avg_duration_controller_test.rb` - Added date filtering tests
- ✓ `test/controllers/sites/bounce_rate_controller_test.rb` - Added date filtering tests
- ✓ `test/controllers/sites/pathnames_controller_test.rb` - Added date filtering tests
- ✓ `test/components/date_range_selector_component_test.rb` - New component tests

## Testing

Component tests for filtering:
- `test/components/pathname_summary_component_test.rb` - Tests hostname column rendering
- `test/controllers/sites/pathnames_controller_test.rb` - Tests grouping logic with display_hostname flag

Controller tests verify that filtering works across all intervals (hourly, daily, weekly).
