# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-24

### Added
- Initial release of Fundii Database Migration Tool
- Support for PostgreSQL migrations
- Support for MongoDB migrations
- Separate schema and seed migration types
- Command-line flags for flexible migration control
  - Database selection: postgres, mongo, or all
  - Migration type: schema, seed, or all
  - Actions: up, down, version
  - Verbose logging option
- Docker support with multi-stage build
- Kubernetes Job manifests for automated migrations
- Kubernetes CronJob for scheduled migrations
- Makefile for simplified operations
- Comprehensive README in Thai
- Quick start guide
- Example migration files for both databases
- GitHub Actions CI/CD pipeline
- Environment variable configuration
- Proper error handling and logging

### Features
- Multi-database support (PostgreSQL + MongoDB)
- Flexible migration control via command-line flags
- Docker-ready with optimized image size
- Kubernetes-native deployment
- Non-root container execution for security
- Automatic job cleanup with TTL
- Retry logic with backoff
- Resource limits and requests
- Connection pooling and timeout handling
- Migration versioning support
- Rollback capabilities

### Documentation
- Complete Thai README with examples
- Quick start guide for rapid deployment
- Kubernetes deployment instructions
- Troubleshooting guide
- Migration file naming conventions
- Best practices

## [Unreleased]

### Added
- Go-based migration generator (`cmd/generator/main.go`)
  - Parse YAML templates and generate migration files
  - Support for PostgreSQL tables with columns, indexes, constraints, foreign keys
  - Support for MongoDB collections with validators and indexes
  - Type-safe YAML parsing with proper structs
  - No external dependencies (yq, Python, PyYAML not needed)
  - Integrated with Makefile (`make generate FILE=...`)
  - Auto-incrementing version numbers
  - Generates both UP and DOWN migrations
- Added `build-generator` target in Makefile
- Updated GENERATOR.md to reflect Go implementation
- Added README for generator command
- Backup old bash script as `.bak`

### Changed
- Replaced bash + Python migration generator with pure Go implementation
- Updated documentation to remove yq/Python requirements
- Clean target now removes generator binary

### Planned
- Add migration dry-run mode
- Add migration validation before execution
- Support for more databases (MySQL, Redis, etc.)
- Migration history tracking
- Web UI for migration management
- Metrics and monitoring integration
- Slack/Discord notifications on migration completion
- Migration script templating
- Database backup before migration option
