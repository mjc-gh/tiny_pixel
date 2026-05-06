# TinyPixel [![CI](https://github.com/mjc-gh/tiny_pixel/actions/workflows/ci.yml/badge.svg)](https://github.com/mjc-gh/tiny_pixel/actions/workflows/ci.yml) ![GitHub Tag](https://img.shields.io/github/v/tag/mjc-gh/tiny_pixel?label=latest)

**Privacy-First Web Analytics** — Self-hosted analytics that respects
user privacy. Built with Rails and SQLite.

For more information, visit [tinypixel.tech](https://tinypixel.tech/).

## Features

### 🔒 Privacy First

Your data stays on your servers. No third-party tracking, no cookie walls, no invasive data collection. Users aren't tracked across the web.

### ⚡ Lightweight

TinyPixel adds minimal overhead to your application. A single 2KB script is all you need to start collecting analytics.

### 🗄️ Self-Hosted

Deploy TinyPixel on your own infrastructure. Complete control over your data with no vendor lock-in.

### 📊 Real-Time Insights

Watch visitor patterns as they happen with hourly, daily, and weekly stats by default.

## Why TinyPixel?

Most analytics platforms track too much and respect privacy too little. TinyPixel is built for developers who want insights without the ethical compromises.

- No user tracking across sites
- No personal data collection
- No AI profiling
- Full data ownership

## Development

### Getting Started

This project is built with **Ruby on Rails 8.1**, SQLite, and Stimulus.
For development guidelines, see [AGENTS.md](./AGENTS.md).

### Contributing

**PRs are limited to contributors.** If you'd like to contribute, please
reach out via [GitHub
Discussions](https://github.com/mjc-gh/tiny_pixel/discussions).

**For suggesting new features**, please use the [ideas
section](https://github.com/mjc-gh/tiny_pixel/discussions/categories/ideas)
rather than opening issues or PRs. This helps us organize feedback and
plan future development.

### Setup

#### Running Tests

GitHub CI will enforce 100% code coverage:

```bash
COVERAGE=1 ./bin/rails t
```

#### Linting

```bash
./bin/rubocop
```

## Resources

- [Discussions](https://github.com/mjc-gh/tiny_pixel/discussions)
- [GitHub](https://github.com/tinypixel)
- [Documentation](https://tinypixel.tech/docs)

## License

TinyPixel is open source and available under an open source license.
