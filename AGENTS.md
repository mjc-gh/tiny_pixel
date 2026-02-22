# AGENTS.md - Development Guidelines for tiny_pixel

## Project Overview

**tiny_pixel** is a privacy-friendly, self-hosted web analytics application built with **Ruby on Rails 8.1**. The codebase uses SQLite for data storage, Stimulus for JavaScript interactivity, and RuboCop for linting.

## Build, Lint, and Test Commands

### Running Tests
- **Run all tests**: `bundle exec rails test`
- **Run a single test file**: `bundle exec rails test test/models/site_test.rb`
- **Run a specific test method**: `bundle exec rails test test/models/site_test.rb:SiteTest#test_method_name`
- **Run tests matching a pattern**: `bundle exec rails test --name pattern`
- **Run tests with verbose output**: `bundle exec rails test -v`
- **Run tests in parallel** (default): Tests run with `:number_of_processors` workers via `parallelize` in `test/test_helper.rb`

### Linting and Code Quality
- **Run RuboCop**: `bundle exec rubocop`
- **Auto-fix RuboCop issues**: `bundle exec rubocop -a`

### Build Commands
- **Development server**: `bundle exec rails server`
- **Database migrations**: `bundle exec rails db:migrate`
- **Database setup**: `bundle exec rails db:setup`
- **Console**: `bundle exec rails console`

## Code Style Guidelines

### General Formatting
- **Ruby version**: 3.3
- **Line ending**: Unix style (LF)
- **Indentation**: 2 spaces (not tabs)
- **Frozen string literals**: Required at the top of all files (`# frozen_string_literal: true`)
- **Line length**: Aim for 80 chars; RuboCop enforces this with warnings

### Imports and Dependencies
- Place `require` statements at the top after `frozen_string_literal` comment
- Group imports logically: standard library, gems, then local requires
- Use relative requires for local files: `require_relative "../config/application"`

### Naming Conventions
- **Classes**: PascalCase (e.g., `ApplicationMailer`, `AnalyticsRecord`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `PROPERTY_ID_LENGHT`)
- **Methods**: snake_case (e.g., `set_property_id`, `cycle_salt`)
- **Variables**: snake_case
- **Private methods**: Prefix with underscore (e.g., `_internal_method`)
- **Boolean methods**: End with `?` (e.g., `valid?`, `need_to_cycle_salt?`)

### Types and Validations
- Use Rails **enums** for fixed state values (not type hints)
  - Example: `enum :device_type, { desktop: 1, mobile: 2, crawler: 9, other: 10 }, scopes: false, prefix: true`
- Use `validates` for model validations
  - Example: `validates :name, :property_id, :salt, presence: true`
  - Use `length: { maximum: 60 }` for string length constraints
- Use model associations: `has_many`, `belongs_to`, `has_one`

### Scope and Associations
- Define scopes as lambdas: `scope :need_to_cycle_salt, -> { where(...) }`
- Use foreign keys and primary keys explicitly when needed
- Abstract classes: Set `self.abstract_class = true` for models that don't map to tables

### Error Handling
- Use Rails exception types: `ActiveRecord::RecordNotFound`, `ActiveRecord::ValidationError`
- Use `before_validation`, `before_create`, `before_save` hooks for data preparation
- Raise meaningful exceptions with descriptive messages
- Include TODO comments for incomplete error handling (see existing code pattern)

### Class and Method Structure
- Place callbacks (`before_create`, `before_validation`, etc.) at the top of class body
- Define enums before associations
- Define scopes before validations
- Use singleton methods in `class <<self` blocks for class-level utility methods
- Keep method bodies concise; extract helper methods for complex logic

### Comments and Documentation
- Use `#` for single-line comments
- Comment non-obvious logic, workarounds, and TODOs
- Mark incomplete work with `# TODO:` comments with description

### Database Models
- Inherit from `ApplicationRecord` for main database models
- Inherit from `AnalyticsRecord` for analytics/analytics-only models (uses separate database)
- Use `self.table_name = :table_name` only if table name differs from Rails convention
- Connect to specific databases: `connects_to database: { writing: :ingestion }`

### Controllers and Views
- Use `frozen_string_literal: true` at the top
- Follow RESTful conventions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- Use strong parameters: `params.require(:model).permit(:field1, :field2)`
- Render JSON or HTML appropriately for endpoint purpose

## Key Project Details

- **Test Framework**: Rails default (Minitest)
- **Parallel Testing**: Enabled by default in `test/test_helper.rb`
- **Test Fixtures**: Located in `test/fixtures/`
- **RuboCop Config**: `.rubocop.yml` with RuboCop-Rails extension enabled
- **Target Ruby**: 3.3
- **Database**: SQLite (primary and ingestion databases)
- **Linter**: RuboCop with rubocop-rails
- **Security Scanner**: Brakeman

## Common Tasks for Agents

1. **Adding a Model**: Create file in `app/models/`, add validations, enums, and associations
2. **Adding Tests**: Create test file in `test/models/`, use fixtures, follow naming conventions
3. **Fixing Linting Errors**: Run `bundle exec rubocop -a` to auto-fix, then manual review
4. **Running Single Test**: Use `bundle exec rails test path/to/test_file.rb:ClassName#test_method`
5. **Debugging**: Use `bundle exec rails console` for interactive exploration

## Important Files
- `app/models/` - Model definitions (Site, Visitor, PageView, AnalyticsRecord)
- `test/models/` - Model tests using Minitest
- `test/test_helper.rb` - Test configuration with parallel execution
- `.rubocop.yml` - RuboCop style rules (Ruby 3.3 target)
- `Gemfile` - Dependencies
