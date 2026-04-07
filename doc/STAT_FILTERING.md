# Stat Filtering Pattern

tiny_pixel implements a consistent filtering pattern across all stat display controllers. This pattern allows users to filter dashboard charts by pathname and hostname (when enabled).

## Overview

The filtering system works through a three-layer pipeline:

1. **Frontend (Stimulus)** - User clicks on a table row, capturing pathname and hostname
2. **URL Parameters** - Stimulus updates turbo-frame URLs with query params
3. **Backend (Controllers)** - Controllers filter database queries based on params

## Architecture

### Frontend: Stimulus Filter Controller

**File:** `app/javascript/controllers/pathname_filter_controller.js`

The Stimulus controller manages user interactions and URL updates:

- **selectPathname()** - Called when user clicks a pathname row
  - Extracts `pathname` and `hostname` from row `data-*` attributes
  - Updates frame URLs with both values as query parameters
  - Shows filter indicator displaying active filter

- **clearFilter()** - Resets all filters
  - Clears pathname and hostname values
  - Updates frame URLs to remove filter parameters
  - Hides filter indicator

- **updateFrameSources()** - Updates all turbo-frame URLs
  - Builds query string: `?interval=daily&pathname=...&hostname=...`
  - Updates all stat chart frames: page_views, visitors, avg_duration, bounce_rate

### Backend: IntervalStats Concern

**File:** `app/controllers/concerns/interval_stats.rb`

Provides filter helper methods available to all stat controllers:

```ruby
helper_method :current_interval, :current_pathname, :current_hostname, :stats_time_column

def current_pathname
  @current_pathname ||= params[:pathname]
end

def current_hostname
  @current_hostname ||= params[:hostname]
end
```

### Backend: Stat Controllers

All stat controllers (`PageViewsController`, `VisitorsController`, `AvgDurationController`, `BounceRateController`) follow the same filtering pattern:

```ruby
def index
  scope = stats_model.for_site(@site.id)
  scope = scope.for_pathname(current_pathname) if current_pathname.present?
  scope = scope.where(hostname: current_hostname) if current_hostname.present?
  
  @chart_data = {
    "Page Views" => scope.group(stats_time_column).sum(:pageviews),
    "Unique Page Views" => scope.group(stats_time_column).sum(:unique_pageviews)
  }
end
```

## When Hostname Filtering is Available

Hostname filtering is only enabled when a site has `display_hostname: true`. The pathname summary component conditionally renders the hostname column and includes `data-hostname` attributes on table rows.

**Files involved:**
- `PathnameSummaryComponent` - Conditionally renders hostname column
- `PathnamesController` - Groups stats by hostname+pathname when display_hostname is true
- `sites/show.html.erb` - Passes hostname parameter to all stat frames

## Adding New Stat Filters

To add a new filterable dimension:

1. **Add a param accessor** to `IntervalStats` concern:
   ```ruby
   def current_my_dimension
     @current_my_dimension ||= params[:my_dimension]
   end
   ```

2. **Update filter logic** in stat controllers:
   ```ruby
   scope = scope.where(my_dimension: current_my_dimension) if current_my_dimension.present?
   ```

3. **Update Stimulus controller** to capture and pass the dimension:
   ```javascript
   const myDimension = event.currentTarget.dataset.myDimension
   const myDimensionParam = myDimension ? `&my_dimension=${encodeURIComponent(myDimension)}` : ""
   ```

4. **Update view URLs** to include the new parameter:
   ```erb
   site_page_views_path(@site, interval: current_interval, my_dimension: current_my_dimension)
   ```

5. **Add data attributes** to table rows or summary components to capture the dimension

## Testing

Component tests for filtering:
- `test/components/pathname_summary_component_test.rb` - Tests hostname column rendering
- `test/controllers/sites/pathnames_controller_test.rb` - Tests grouping logic with display_hostname flag

Controller tests verify that filtering works across all intervals (hourly, daily, weekly).
