# AGENTS.md - Development Guidelines for tiny_pixel

## Project Overview

**tiny_pixel** is a privacy-friendly, self-hosted web analytics application built with **Ruby on Rails 8.1**. The codebase uses SQLite for data storage, Stimulus for JavaScript interactivity.

## Development

### Running Tests
- **Run all tests**: `bundle exec rails t`
- **Run a single test file**: `bundle exec rails t test/models/site_test.rb`
- **Run tests matching a pattern**: `bundle exec rails t --name pattern`
- **Run tests with coverage**: `COVERAGE=1 bundle exec rails t"`

### Linting and Code Quality
- **Run RuboCop**: `bundle exec rubocop`
- **Auto-fix RuboCop issues**: `bundle exec rubocop -A`

## Code Style Guidelines

### Writing Tests
- Do not add unnecessary comments to tests
- Do not test built-in model validations
- Snake case all parts of variable names:
  ```ruby
  # GOOD
  pixel_req_1 = obj.method

  # BAD
  pixel_req1 = obj.method
  ```

### General Formatting
- **Ruby version**: 3.4
- **Line ending**: Unix style (LF)
- **Indentation**: 2 spaces (not tabs)
- **Frozen string literals**: Required at the top of all files (`# frozen_string_literal: true`)
- **Always use snake case**: Use `req_1` instead of `req1`

### Scope and Associations
- Define scopes as lambdas: `scope :need_to_cycle_salt, -> { where(...) }`
- Use foreign keys and primary keys explicitly when needed

### Error Handling
- Use Rails exception types: `ActiveRecord::RecordNotFound`, `ActiveRecord::ValidationError`
- Use `before_validation`, `before_create`, `before_save` hooks for data preparation
- Raise meaningful exceptions with descriptive messages

### Class and Method Structure
- Place callbacks (`before_create`, `before_validation`, etc.) at the top of class body
- Define enums before associations
- Define scopes before validations

### Comments and Documentation
- Use `#` for single-line comments
- Do not write unnecessary comments

### Database Models
- Inherit from `ApplicationRecord` for main database models
- Inherit from `AnalyticsRecord` for analytics/analytics-only models (uses separate database)
- Use `self.table_name = :table_name` only if table name differs from Rails convention
- Connect to specific databases: `connects_to database: { writing: :ingestion }`

### Controllers and Views
- Follow RESTful conventions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- Use strong parameters: `params.require(:model).permit(:field1, :field2)`
- Render JSON or HTML appropriately for endpoint purpose

## Key Project Details

- **Test Framework**: Rails default (Minitest)
- **Test Fixtures**: Located in `test/fixtures/`
- **RuboCop Config**: `.rubocop.yml` with RuboCop-Rails extension enabled
- **Code Coverage**: simplecov test coverage; table outputs to console with `COVERAGE` env var
- **Target Ruby**: 3.4
- **Database**: SQLite (primary and ingestion databases)
- **Linter**: RuboCop with rubocop-rails
- **Security Scanner**: Brakeman
