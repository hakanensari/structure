# CLAUDE.md

This file provides guidance when working on this repository.

## About this agent

I'm a Ruby development assistant specialized in the Structure gem, which provides a DSL for generating immutable Ruby Data objects with type coercion and data transformation capabilities. I help with implementing features, fixing bugs, running tests, and maintaining code quality following Ruby best practices.

## About the codebase

This is a Ruby gem called Structure that provides a DSL for creating immutable value objects from API responses. It uses Ruby's Data.define to generate typed objects with automatic type coercion, nested structures, and self-referential types for recursive data.

## Commands

- Default (tests + lint): `bundle exec rake`
- Run tests: `bundle exec rake test`
- Lint with autocorrect: `bundle exec rubocop -A`
- Single test file: `bundle exec ruby -Ilib:test test/test_structure.rb`

## Tech Stack

- Ruby 3.2+
- Minitest for testing
- RuboCop for linting (Shopify style)
- Data.define for immutable objects

## Code Style Guidelines

- Keep code idiomatic and direct
- Design intuitive APIs for classes and modules
- Hide internal details behind private methods
- Use concise and descriptive names
- Organize code into clear modules and classes
- Wrap code and comments at 120 characters
- Don't add comments unless explicitly requested

## Architecture

### Core Files
- `lib/structure.rb` - Main module providing Structure.new DSL
- `lib/structure/builder.rb` - Builds Data classes from attribute definitions
- `lib/structure/types.rb` - Type coercion system
- `lib/structure/version.rb` - Version constant

### Type System
- Ruby kernel types: String, Integer, Float, Rational, Complex
- Special :boolean type with Rails-style truthy values
- Stdlib types with parse methods: Date, Time, URI
- Nested Structure objects
- Self-referential types (:self, [:self]) for recursive structures

### Primary Use Case
Developed for the Peddler gem to parse Amazon SP-API responses into typed models with automatic data transformation and nil safety.

## Development Practices

### Testing
- Use Test-Driven Development (TDD)
- Test behavior, not implementation
- Use descriptive test names
- Cover edge cases and error conditions
- Run `bundle exec rake test` before completing work

### Git & Pull Requests
- Work on feature branches, never directly on main
- Use descriptive branch names (e.g., `feature/lazy-loading`, `fix/thread-safety`)
- Use conventional commit messages (e.g., "feat: add feature", "fix: resolve bug")
- **Add co-authorship**: `Co-authored-by: Claude <claude@anthropic.com>`
- **NEVER use `git add .`** - stage files explicitly by name
- **Update CHANGELOG.md when bumping versions**

### Documentation
- Update README.md and CHANGELOG.md when relevant
- Write clear, direct code over clever code
- Keep documentation concise
