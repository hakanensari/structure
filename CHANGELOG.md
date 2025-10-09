# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [4.1.0] - 2025-10-09

### Added

- Support for defining custom instance and class methods within `Structure.new` blocks, matching `Data.define` behavior
  ```ruby
  User = Structure.new do
    attribute(:age, Integer)

    def adult?
      age >= 18
    end

    def self.legal_age
      18
    end
  end
  ```

### Fixed

- Complete RBS type signature generation with missing standard Data class methods (`[]`, `members`)
- RBS output now follows `RBS::Sorter` conventions for consistency with Ruby's official tooling

## [4.0.0] - 2025-09-30

### Added

- Add `attribute?` method for defining optional attributes (inspired by the API of [dry-struct](https://dry-rb.org/gems/dry-struct/1.0/))

### Changed

- `attribute` now defines required attributes (key must be present in input hash)

## [3.7.0] - 2025-01-30

### Performance

- Optimize parsing for speed improvements

## [3.6.3] - 2025-01-27

### Fixed

- Fix RBS generation to use typed signatures instead of bare Array/Hash types in to_h method
- Fix invalid type specifications to raise ArgumentError instead of being silently ignored

## [3.6.2] - 2025-09-27

### Fixed

- Add thread safety to string class resolution using mutex for concurrent parsing

## [3.6.1] - 2025-09-26

### Added

- Add Steep type checking to default Rake task and CI workflow

### Fixed

- Fix RBS type signatures to use specific class names instead of `instance` keyword for Steep compatibility

## [3.6.0] - 2025-09-25

### Added

- Support for string class names in attribute declarations for lazy resolution and circular dependencies

## [3.5.0] - 2025-09-25

### Added

- Generate proper RBS type signatures for array attributes
- Generate type-safe `parse_data` types in RBS for self-referential structures
- Improve type validation with TypeError for non-array values passed to array attributes

### Fixed

- Fixed passing parsed instances in self-referential arrays
- Fixed RuboCop block nesting offense in RBS module

## [3.4.0] - 2025-09-24

### Added

- RBS type signature generation with `Structure::RBS.emit` and `Structure::RBS.write`

## [3.3.0] - 2025-09-12

### Added

- Override `to_h` to recursively convert nested Data objects and custom objects with `to_h` methods to plain hashes

## [3.2.0] - 2025-09-11

### Added

- Self-referential type support with `:self` and `[:self]` markers for building tree structures and other recursive data types

## [3.1.1] - 2025-09-03

### Fixed

- Skip predicate method generation for boolean attributes ending with `?` to avoid awkward `??` methods

## [3.1.0] - 2025-01-29

### Added

- `after_parse` callback hook for validation and post-processing logic

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
[3.1.0]: https://github.com/hakanensari/structure/compare/v3.0.0...v3.1.0
[3.1.1]: https://github.com/hakanensari/structure/compare/v3.1.0...v3.1.1
[3.2.0]: https://github.com/hakanensari/structure/compare/v3.1.1...v3.2.0
[3.3.0]: https://github.com/hakanensari/structure/compare/v3.2.0...v3.3.0
[3.4.0]: https://github.com/hakanensari/structure/compare/v3.3.0...v3.4.0
[3.5.0]: https://github.com/hakanensari/structure/compare/v3.4.0...v3.5.0
[3.6.0]: https://github.com/hakanensari/structure/compare/v3.5.0...v3.6.0
[3.6.1]: https://github.com/hakanensari/structure/compare/v3.6.0...v3.6.1
[3.6.2]: https://github.com/hakanensari/structure/compare/v3.6.1...v3.6.2
[3.6.3]: https://github.com/hakanensari/structure/compare/v3.6.2...v3.6.3
[3.7.0]: https://github.com/hakanensari/structure/compare/v3.6.3...v3.7.0
[4.0.0]: https://github.com/hakanensari/structure/compare/v3.7.0...v4.0.0
[Unreleased]: https://github.com/hakanensari/structure/compare/v4.0.0...HEAD
