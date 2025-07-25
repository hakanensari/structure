# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [3.0.0]

### Changed

- **BREAKING:** Complete API rewrite from `Structure.define` to `Structure.new` with cleaner DSL
- **BREAKING:** Uses Ruby's `Data.define` for immutable objects (requires Ruby 3.2+)
- **BREAKING:** Simplified attribute definition syntax
- Automatic predicate method generation for boolean attributes (e.g., `active?`)
- Improved type coercion system with better error handling
- Enhanced nested object parsing with Array[Type] syntax
- Better nil safety and data transformation capabilities

### Added

- Support for custom transformation blocks in attribute definitions
- Built-in support for `:boolean` type with Rails-style truthy values
- Automatic generation of predicate methods for boolean attributes
- Enhanced array type coercion with `[Type]` syntax
- Better integration with API response parsing workflows

### Removed

- **BREAKING:** Legacy `Structure.define` syntax (replaced with `Structure.new`)
- **BREAKING:** Old attribute definition patterns
- **BREAKING:** Support for Ruby versions below 3.2

## [2.3.0]

### Added

- Add marshaling support

## [2.2.0]

### Added

- Respect existing comparison

## [2.1.0]

### Added

- Allow including in another module

## [2.0.0]

### Removed

- Do not handle nested objects when casting to hash
- Remove .double

### Changed

- Do not freeze by default
- Change string formatting

[2.0.0]: https://github.com/hakanensari/structure/compare/v1.2.1...v2.0.0
[2.1.0]: https://github.com/hakanensari/structure/compare/v2.0.0...v2.1.0
[2.2.0]: https://github.com/hakanensari/structure/compare/v2.1.0...v2.2.0
[2.3.0]: https://github.com/hakanensari/structure/compare/v2.2.0...v2.3.0
[3.0.0]: https://github.com/hakanensari/structure/compare/v2.3.0...v3.0.0
[Unreleased]: https://github.com/hakanensari/structure/compare/v3.0.0...HEAD
