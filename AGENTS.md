# Development Guidelines - tiny_pixel

**tiny_pixel**: Privacy-friendly, self-hosted web analytics built with **Ruby on Rails 8.1**, SQLite, and Stimulus.

## Quick Commands

| Task | Command |
|------|---------|
| Generate | `be rails g [model\|controller\|job\|component]` |
| Test | `be rails t` \| `be rails t test/models/site_test.rb` \| `be rails t --name pattern` |
| Coverage | `COVERAGE=1 be rails t` |
| Lint | `be rubocop` |
| Auto-fix | `be rubocop -A` |

## Code Style

**Formatting**: Ruby 3.4, 2-space indentation, Unix line endings (LF)

**Required**: 
- Frozen string literals at top of `.rb` files: `# frozen_string_literal: true`
- Snake case naming: `req_1` not `req1`
- No unnecessary comments or tests for built-in validations

**Structure**:
- Callbacks → Enums → Scopes → Validations (in class body)
- Scopes as lambdas: `scope :name, -> { where(...) }`
- Rails exceptions: `ActiveRecord::RecordNotFound`, `ActiveRecord::ValidationError`

**Models**:
- Inherit from `ApplicationRecord` (main) or `AnalyticsRecord` (analytics-only)
- Use explicit foreign/primary keys when needed
- Use `self.table_name` only if non-standard

**Controllers**: RESTful conventions with strong parameters  
**Views**: Render JSON or HTML per endpoint purpose

## References

- **Stats Models**: See `@doc/AGGREGATED_STATS.md` for `HourlyPageStat`, `DailyPageStat`, `WeeklyPageStat`
- **ViewComponents**: See `@app/components`
- **Stack**: Minitest, simplecov, RuboCop-Rails, Brakeman
- **Databases**: SQLite (primary + ingestion)
