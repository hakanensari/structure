# Performance Optimization Opportunities

**Date:** 2025-10-08
**Status:** Proposed
**Impact:** Low-hanging fruit, estimated 10-25% improvement on parsing hot paths

## Summary

After reviewing the codebase, I identified 5 low-hanging fruit optimizations that could provide measurable performance improvements without compromising code clarity. These are ranked by impact.

## Optimizations (Ranked by Impact)

### 1. Use Set for BOOLEAN_TRUTHY (High Impact)

**File:** `lib/structure/types.rb:9`

**Current:**
```ruby
BOOLEAN_TRUTHY = [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].freeze
# ...
->(val) { BOOLEAN_TRUTHY.include?(val) }
```

**Issue:** `Array#include?` is O(n) linear search through 9 elements

**Proposed:**
```ruby
require 'set'

BOOLEAN_TRUTHY = Set.new([true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"]).freeze
# ...
->(val) { BOOLEAN_TRUTHY.include?(val) }
```

**Impact:**
- O(1) hash lookup vs O(n) array scan
- Estimated 30-40% faster for boolean coercion
- Zero code changes outside this file
- Adds Set dependency (stdlib, zero cost)

**Trade-off:** Requires `require 'set'` at top of file

---

### 2. Cache Coercions in parse Method (Medium-High Impact)

**File:** `lib/structure.rb:109`

**Current:**
```ruby
final       = {}
mappings    = __structure_meta__[:mappings]
defaults    = __structure_meta__[:defaults]
after_parse = __structure_meta__[:after_parse]
required    = __structure_meta__[:required]
# ... later in loop:
coercion = __structure_meta__[:coercions][attr]  # Hash lookup in hot path
value = coercion.call(value) if coercion
```

**Issue:** Looking up `__structure_meta__[:coercions]` inside the mapping loop

**Proposed:**
```ruby
final       = {}
mappings    = __structure_meta__[:mappings]
defaults    = __structure_meta__[:defaults]
coercions   = __structure_meta__[:coercions]  # Cache here
after_parse = __structure_meta__[:after_parse]
required    = __structure_meta__[:required]
# ... later in loop:
coercion = coercions[attr]  # Local variable lookup
value = coercion.call(value) if coercion
```

**Impact:**
- Avoids hash lookup in hot path (called once per attribute)
- Estimated 5-10% improvement on parse performance
- Consistent with existing pattern (mappings, defaults already cached)

**Trade-off:** None - pure win

---

### 3. Cache Resolved Class in String Array Coercion (Medium Impact)

**File:** `lib/structure/types.rb:96-103`

**Current:**
```ruby
when String
  lambda do |value|
    unless value.respond_to?(:map)
      raise TypeError, "can't convert #{value.class} into Array"
    end

    resolved_class = resolve_class(element_type, context)  # Resolves every time
    value.map { |element| resolved_class.parse(element) }
  end
```

**Issue:** `resolve_class` is called every time the lambda is invoked (on every parse call)

**Proposed:**
```ruby
when String
  resolved_class = nil  # Cache outside lambda

  lambda do |value|
    unless value.respond_to?(:map)
      raise TypeError, "can't convert #{value.class} into Array"
    end

    resolved_class ||= resolve_class(element_type, context)  # Resolve once
    value.map { |element| resolved_class.parse(element) }
  end
```

**Impact:**
- Avoids expensive constant resolution on repeated parses
- Matches existing `lazy_class` pattern (lines 75-83)
- Estimated 15-25% improvement for arrays of structured objects
- Critical for nested/recursive structures

**Trade-off:** None - pure win, follows existing pattern

---

### 4. Optimize Predicate Method Name Generation (Low-Medium Impact)

**File:** `lib/structure/builder.rb:99`

**Current:**
```ruby
def predicate_methods
  @types.filter_map do |name, type|
    if type == :boolean
      ["#{name}?".to_sym, name] unless name.to_s.end_with?("?")
    end
  end.to_h
end
```

**Issues:**
- String interpolation: `"#{name}?"` creates string, then `.to_sym` converts it
- `name.to_s` called on symbol
- Called during class definition (not hot path, but still wasteful)

**Proposed:**
```ruby
def predicate_methods
  @types.filter_map do |name, type|
    if type == :boolean
      name_str = name.to_s
      unless name_str.end_with?("?")
        ["#{name_str}?".to_sym, name]
      end
    end
  end.to_h
end
```

Or even better:
```ruby
def predicate_methods
  @types.filter_map do |name, type|
    if type == :boolean
      name_str = name.to_s
      unless name_str.end_with?("?")
        [:"#{name_str}?", name]  # Symbol literal interpolation
      end
    end
  end.to_h
end
```

**Impact:**
- Avoids redundant `.to_s` calls
- Only affects class definition time (not parse time)
- Estimated 5-10% faster structure definition
- More readable

**Trade-off:** None - clearer and faster

---

### 5. Extract Lambda in to_h Method (Low Impact)

**File:** `lib/structure.rb:66`

**Current:**
```ruby
klass.define_method(:to_h) do
  klass.members.to_h do |m|
    v = public_send(m)
    value = case v
    when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
    when ->(x) { x.respond_to?(:to_h) && x } then v.to_h  # Lambda created each time
    else v
    end
    [m, value]
  end
end
```

**Issue:** Lambda `-> (x) { x.respond_to?(:to_h) && x }` is created every time `to_h` is called

**Proposed:**
```ruby
# At module level
TO_H_CHECKER = ->(x) { x.respond_to?(:to_h) && x }
private_constant :TO_H_CHECKER

# In method definition
klass.define_method(:to_h) do
  klass.members.to_h do |m|
    v = public_send(m)
    value = case v
    when Array then v.map { |x| x.respond_to?(:to_h) && x ? x.to_h : x }
    when TO_H_CHECKER then v.to_h
    else v
    end
    [m, value]
  end
end
```

**Impact:**
- Avoids lambda allocation on every `to_h` call
- `to_h` is not a hot path (mostly for debugging/serialization)
- Estimated <5% improvement on `to_h` performance

**Trade-off:** Very minor - adds one module constant

---

## Bonus: Potential Future Optimizations (Not Low-Hanging)

### 6. Optimize Double Hash Lookup in Parse

**File:** `lib/structure.rb:102-106`

**Current:**
```ruby
mappings.each do |attr, from|
  value = data.fetch(from) do
    data.fetch(from.to_sym) do  # Double lookup
      defaults[attr]
    end
  end
```

**Issue:** Tries string key, then symbol key (two hash lookups per attribute)

**Possible approaches:**
1. Normalize all keys upfront (single pass through data)
2. Check which key exists first, then fetch once
3. Use `data[from] || data[from.to_sym] || defaults[attr]`

**Why not low-hanging:**
- Need to handle nil values correctly (can't use `||`)
- `fetch` with block is for missing keys, nil values should pass through
- More complex logic, easier to introduce bugs

**Decision:** Skip for now - would need careful testing

---

## Implementation Priority

1. **#2 - Cache coercions** (trivial, zero risk, consistent with existing code)
2. **#3 - Cache resolved class** (follows existing pattern, high impact for arrays)
3. **#1 - Set for booleans** (simple, measurable win, requires Set)
4. **#4 - Predicate method** (cleanup, minor win)
5. **#5 - Extract lambda** (cleanup, minimal impact)

## Benchmarking Plan

Use existing `benchmarks/perf_comparison.rb` as baseline:

```bash
# Before optimizations
ruby benchmarks/perf_comparison.rb > before.txt

# After each optimization
ruby benchmarks/perf_comparison.rb > after_optimization_N.txt

# Compare results
```

Create specific microbenchmarks for:
- Boolean coercion (test #1)
- Array parsing with nested structures (test #3)
- Multiple parse calls on same structure (test #2)

## Testing Requirements

- All existing tests must pass
- No new dependencies (except `require 'set'` from stdlib)
- RBS signatures must remain valid
- Steep type checking must pass

## Code Style Considerations

All optimizations maintain:
- Frozen string literals
- Clear, readable code
- Consistent with existing patterns
- No magic numbers or unclear optimizations

## Estimated Total Impact

Combining all optimizations:
- **Parse performance:** 10-20% improvement on typical payloads
- **Boolean coercion:** 30-40% improvement
- **Array parsing:** 15-25% improvement
- **Memory:** Negligible change (maybe 1-2% improvement from reduced allocations)

Most realistic scenario (typical API response with mixed types):
- **Overall improvement: 10-15%** on parsing hot path

## References

- Existing benchmark: `benchmarks/perf_comparison.rb`
- Type system: `lib/structure/types.rb`
- Core parsing: `lib/structure.rb:78-119`
- Builder: `lib/structure/builder.rb`
