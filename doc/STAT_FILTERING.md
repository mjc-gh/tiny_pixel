# Stat Filtering Pattern

tiny_pixel implements a consistent filtering pattern across all stat display controllers. This pattern allows users to filter dashboard charts by pathname, hostname (when enabled), date range, and dimension values (country, browser, device type, referrer).

## Overview

The filtering system works through a three-layer pipeline:

1. **Frontend (Stimulus + Components)** - User selects filters via UI (table clicks, date inputs)
2. **URL Parameters** - Stimulus navigates with Turbo.visit, passing all filter params in URL
3. **Backend (Controllers)** - Servers receive request, render page with filtered data in turbo frames

Supported filters:
- **Pathname** - Filter by page path (e.g., `/`, `/about`)
- **Hostname** - Filter by domain (when `display_hostname: true` on site)
- **Date Range** - Filter by start and end dates using HTML5 date inputs
- **Dimension** - Filter by dimension type and value (country, browser, device_type, referrer_hostname)

## Architecture

### Frontend: Stimulus Dashboard Controller

**File:** `app/javascript/controllers/site_dashboard_controller.js`

The Stimulus controller manages filter state and URL navigation. All filter state is stored as Stimulus values and persisted in turbo frame URLs. Supported state values include `pathname`, `hostname`, `startDate`, `endDate`, `dimensionType`, and `dimensionValue`.

Key methods:
- **selectPathname(event)** - Called when user clicks a pathname row
- **selectDimension(event)** - Called when user clicks a dimension table row
- **updateDateRange()** - Called when user changes date inputs
- **clearPathnameFilter()** - Clears pathname/hostname filters, preserves dimension filters
- **clearDimensionFilter()** - Clears dimension filters, preserves pathname filters
- **visit()** - Centralized navigation method that builds URL with all filter state and calls `Turbo.visit()`

### Backend: FilterStats Concern

**File:** `app/controllers/concerns/filter_stats.rb`

Provides filter helper methods available to all stat controllers. Helper methods include:
- `current_pathname` - Extracts pathname filter from params
- `current_hostname` - Extracts hostname filter from params
- `current_dimension_type` - Extracts dimension type with validation
- `current_dimension_value` - Extracts dimension value from params
- `current_start_date` / `current_end_date` - Parse date params
- `apply_date_range_filter(scope)` - Applies date range to query scope

### Backend: Stat Controllers

**Files:** `app/controllers/sites/page_views_controller.rb`, `visitors_controller.rb`, `avg_duration_controller.rb`, `bounce_rate_controller.rb`, `pathnames_controller.rb`

All stat controllers follow the same filtering pattern:

1. Start with base scope filtered by site: `stats_model.for_site(@site.id)`
2. Select dimension scope or global scope based on dimension filter presence
3. Apply pathname, hostname, and date range filters sequentially
4. Group results and return chart data

**Important Scope Pattern:**
- Stats have two top-level scopes: `.global` (for aggregated stats) and `.for_dimension(type, value)` (for dimension-specific stats)
- When a dimension filter is applied, use `.for_dimension()` instead of `.global`
- Other filters (pathname, hostname, date range) are applied on top of whichever scope is selected

**Filter Combination:**
- Multiple filters work together: pathname + hostname + dimension + date range
- Users can combine pathname filters with dimension filters to drill down further
- Dimension tables show breakdowns within the filtered set (e.g., countries filtered by browser=Chrome)

## Dimension Filtering

Dimension filtering allows users to filter the entire dashboard by clicking on dimension values in the four dimension breakdown tables (Countries, Browsers, Device Types, Referrers).

### Supported Dimensions

- **country** - Filter by country code or name
- **browser** - Filter by browser (enum: 1=Chrome, 2=Edge, 3=Safari, 4=Firefox, 5=Opera, 999=Other)
- **device_type** - Filter by device (enum: 1=Desktop, 2=Mobile, 9=Crawler, 10=Other)
- **referrer_hostname** - Filter by referrer domain (e.g., "google.com")

### Enum Value Formatting

Browser and device type dimensions use enum integers in the database but display user-friendly names in the UI. The helper method `format_dimension_value()` in `app/helpers/application_helper.rb` handles conversion for:
- Filter indicator badges
- Dimension breakdown tables
- All user-facing dimension displays

### Dimension Selection UI

**DimensionTableComponent** (`app/components/dimension_table_component.html.erb`):
- Each table row has `data-action="click->site-dashboard#selectDimension"`
- Data attributes: `data-dimension-type` and `data-dimension-value`
- Selected row is highlighted with background color and bold text
- Component receives `selected_dimension_value` to check which row matches current filter

### Multiple Filter Support

Users can combine filters:
- **Pathname + Dimension**: View page "/about" filtered by browser "Chrome"
- **Dimension + Dimension**: Not directly supported (dimension tables group by their own type)
- All combinations: pathname + hostname + dimension + date range

Each filter type has independent clear buttons in the filter indicator UI:
- "Clear Pathname Filter" - keeps dimension filters
- "Clear Dimension Filter" - keeps pathname filters

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
- `FilterStats` concern - Provides `current_start_date`, `current_end_date`, and `apply_date_range_filter` helpers
- All stat controllers - Apply `apply_date_range_filter` to their query scopes
- Stat models - Have `for_date_range` scopes defined for each interval type

**URL Parameter:** `start_date` and `end_date` (ISO8601 format: YYYY-MM-DD)

## Adding New Stat Filters

### Pattern for Simple Filters

To add a new simple filter:

1. Add a param accessor to `app/controllers/concerns/filter_stats.rb`
2. Add to the `helper_method` declaration in `FilterStats`
3. Update filter logic in stat controllers to apply the filter to the query scope
4. Add corresponding Stimulus value to `app/javascript/controllers/site_dashboard_controller.js`
5. Add Stimulus method to handle user selection and call `visit()`
6. Update view URLs to include the new parameter in turbo frame src
7. Add `data-*` attributes to table rows

### Pattern for Enum-Based Filters

For filters with enum values that need friendly display names:

1. Follow the simple filter pattern above
2. Create a helper method in `app/helpers/application_helper.rb` for enum formatting
3. Use the helper in views and components to display user-friendly names

## Testing

Component tests for filtering:
- `test/components/pathname_summary_component_test.rb` - Tests hostname column rendering
- `test/controllers/sites/pathnames_controller_test.rb` - Tests grouping logic with display_hostname flag

Controller tests verify that filtering works across all intervals (hourly, daily, weekly).
