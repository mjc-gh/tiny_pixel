# Development Guidelines - tiny_pixel

**tiny_pixel**: Privacy-friendly, self-hosted web analytics built with **Ruby on Rails 8.1**, SQLite, and Stimulus.

## Quick Commands

| Task | Command |
|------|---------|
| Generate | `./bin/rails g [model\|controller\|job\|component]` |
| Test | `./bin/rails t` \| `./bin/rails t test/models/site_test.rb` \| `./bin/rails t --name pattern` |
| Coverage | `COVERAGE=1 ./bin/rails t` |
| Lint | `./bin/rubocop` |
| ERB Analysis | `./bin/herb analyze .` |
| Auto-fix | `./bin/rubocop -A` |

## Code Style

**Formatting**: Ruby 4, 2-space indentation, Unix line endings (LF)

**Required**:
- Frozen string literals at top of `.rb` files: `# frozen_string_literal: true`
- Snake case naming: `req_1` not `req1`
- One class per `.rb` file
- Never add unnecessary code comments

**Structure**:
- Callbacks → Enums → Scopes → Validations (in class body)
- Scopes as lambdas: `scope :name, -> { where(...) }`

**Models**:
- Inherit from `ApplicationRecord` (main) or `AnalyticsRecord` (analytics-only)
- Use explicit foreign/primary keys when needed
- Use `self.table_name` only if non-standard

**Controllers**:
- RESTful conventions with strong parameters
- Prefer resource routing

**Views**:
- Render JSON or HTML per endpoint purpose
- Run `./bin/herb` to analyze views for syntax errors, formatting, and security issues

**Testing**:
- Prefer less test cases while maximizing code coverage
- Don't test framework features (validations, relations, other declarative APIs)

## References

- **Stats Models**: See `@doc/AGGREGATED_STATS.md` for `HourlyPageStat`, `DailyPageStat`, `WeeklyPageStat`
- **Stat Filtering**: See `@doc/STAT_FILTERING.md` for pathname, hostname, date range, and dimension filtering patterns used in dashboard controllers
- **Tracking Script**: See `@doc/TRACKING_SCRIPT.md` for implementation details of `pkg/tiny_pixel.js`
- **Front-end**: See `@doc/FRONTEND.md` for guidelines on JavasScript for the browser, Stimulus controllers, CSS, Tailwind, and icons
- **ViewComponents**: See `@app/components`
- **Testing Stack**: Minitest, simplecov (with 100% coverage required), RuboCop-Rails, Brakeman
- **Databases**: SQLite (primary + ingestion)
