# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Install dependencies:**

```bash
bundle install
```

**Run tests:**

```bash
rake test
```

**Lint code:**

```bash
# Auto-correct issues:
rubocop -A
```

**Single test file:**

```bash
ruby -Ilib:test test/test_structure.rb
```

## Project Architecture

This is a Ruby gem called **Structure** that provides a DSL for generating immutable Ruby Data objects with type coercion and data transformation capabilities.

### Core Components

- **`lib/structure.rb`** - Main module that provides the `Structure.new` DSL
- **`lib/structure/builder.rb`** - Builder class that accumulates attribute definitions and generates Data classes
- **`lib/structure/types.rb`** - Type coercion module with support for various type conversions
- **`lib/structure/version.rb`** - Version constant

### Test Suite

- **`test/test_core_structure.rb`** - Core DSL and data parsing functionality tests
- **`test/test_type_coercions.rb`** - Type coercion and conversion tests
- **`test/test_stdlib_types.rb`** - Standard library type support tests (Date, Time, URI)
- **`test/test_nested_objects.rb`** - Nested Structure object parsing tests
- **`test/test_boolean_predicates.rb`** - Boolean predicate method generation tests
- **`test/test_after_parse.rb`** - After parse callback functionality tests
- **`test/helper.rb`** - Test helper setup

### Key Design Patterns

**Data Object Generation:** Uses `Data.define` to create immutable value objects with type coercion.

**DSL-Based Configuration:** Clean `attribute` method for defining transformations and type coercion.

**Type System:** Built-in support for Ruby kernel types (`String`, `Integer`, `Float`, `Rational`, `Complex`), `:boolean`, stdlib types with parse methods (`Date`, `Time`, `URI`), and nested Structure objects.

**API Integration Focus:** Designed for parsing API responses with automatic data transformation and nil safety.

**Immutability:** All generated objects are immutable Data objects with pattern matching support.

**Type Coercion:** Automatic conversion between types with graceful error handling.

**After Parse Callbacks:** Optional `after_parse` hook for validation or post-processing logic.

### Testing Approach

Uses Minitest with comprehensive tests covering:

- DSL attribute definition and type coercion
- Data object generation and `.parse` method functionality
- Type system with various data types:
  - Kernel types: String, Integer, Float, Rational, Complex
  - Boolean type with Rails-style truthy values
  - Stdlib types with parse methods: Date, Time, URI
  - Custom types with parse methods (e.g., Money)
- Nested object parsing and Array[Type] syntax
- Transformation blocks and custom data processing
- Nil safety and error handling
- Edge cases (malformed data, missing fields, type conversion errors)
- Boolean predicate methods for :boolean attributes

## Ruby Version Requirements

- Minimum Ruby version: 3.2+ (required for `Data.define`)
- Uses `frozen_string_literal: true` throughout
- Follows Shopify's RuboCop style guide

## Primary Use Case

Structure is being developed primarily for the [Peddler gem](https://github.com/hakanensari/peddler) to generate typed response models for Amazon's SP-API. Structure.new is used to generate models for complex API responses like orders, catalog items, financial transactions, etc.

Example usage:

```ruby
Order = Structure.new do
  attribute :amazon_order_id, String, from: 'AmazonOrderId'
  attribute :total_amount, from: 'OrderTotal' do |data|
    Money.new(data['Amount'], data['CurrencyCode']) if data
  end
  attribute :is_prime, :boolean, from: 'IsPrime'
  
  after_parse do |order|
    raise "Order ID is required" if order.amazon_order_id.nil?
  end
end

order = Order.parse(api_response_data)
```

## Development Practices

### Code Style Guidelines

- Keep code idiomatic and direct. Avoid unnecessary complexity
- Design intuitive APIs for classes and modules. Hide internal details behind private methods
- Use concise and descriptive names
- Organize code into clear modules and classes. Avoid monolithic files
- Wrap code and comments at 120 characters

### Testing

- **Use Test-Driven Development (TDD):**
  1. Write a minimal failing test
  2. Implement the feature
  3. Make sure existing tests still pass
  4. Lint code
  5. Continue with more TDD cycles as needed
- Test behavior, not implementation (don't test private methods directly)
- Use descriptive test names that clearly indicate what is being tested
- Cover edge cases and error conditions

### Git & Pull Requests

- Work on feature branches, never directly on main
- Use descriptive branch names (e.g., `feature/lazy-loading`, `fix/thread-safety`)
- Use conventional commit messages (e.g., "feat: add new feature", "fix: resolve bug")
- **NEVER use `git add .`** - always stage files explicitly by name
- **ALWAYS update CHANGELOG.md when bumping versions** - document breaking changes, new features, and fixes
