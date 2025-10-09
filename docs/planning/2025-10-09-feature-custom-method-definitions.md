# Feature: Custom Method Definitions

## Feature Description

Enable defining custom instance and class methods within `Structure.new` blocks, matching the behavior of Ruby's `Data.define`.

### Current Behavior

```ruby
User = Structure.new do
  attribute :name, String
  attribute :age, Integer

  def adult?  # ❌ Does NOT work - method is defined on Builder, not on the Data class
    age >= 18
  end
end
```

**Workaround (current):**
```ruby
User = Structure.new do
  attribute :name, String
  attribute :age, Integer
end

# Must reopen class
User.class_eval do
  def adult?
    age >= 18
  end
end
```

### Desired Behavior

```ruby
User = Structure.new do
  attribute :name, String
  attribute :age, Integer

  def adult?  # ✅ Should work like Data.define
    age >= 18
  end

  def self.create_admin  # ✅ Class methods too
    parse(name: "Admin", age: 99)
  end
end

User.parse(name: "Bob", age: 25).adult?  # => true
User.create_admin  # => #<data User name="Admin", age=99>
```

## Why This Matters

1. **Consistency with Ruby's Data.define** - Structure wraps Data, so it should support the same API
2. **Better DX** - Define everything in one place without reopening classes
3. **Cleaner code** - Natural co-location of data definition and methods

## Technical Analysis

### Root Cause

**File:** `lib/structure.rb:24`

```ruby
builder = Builder.new
builder.instance_eval(&block) if block  # ← Block evaluated on Builder instance
```

When the block is evaluated on the `Builder` instance, any method definitions (`def adult?`) become methods on the Builder object, not on the final Data class.

### How Data.define Handles This

```ruby
Person = Data.define(:name, :age) do
  def adult?
    age >= 18
  end
end
```

`Data.define` passes the block to the class being created, evaluating it in the class's context via `class_eval`, so method definitions work naturally.

## Implementation Strategy

### Two-Pass Evaluation Approach

**Pass 1:** Extract DSL configuration (attributes, types, mappings, etc.)
- Evaluate block on `Builder` instance to collect metadata
- Builder methods: `attribute`, `attribute?`, `after_parse`

**Pass 2:** Define custom methods
- Evaluate the same block on the Data class to define methods
- Temporarily provide dummy DSL methods to prevent `NoMethodError`
- Remove dummy DSL methods after evaluation

### Why This Works

1. Builder collects all configuration in first pass
2. Data class is created with correct attributes
3. Second pass adds custom methods without affecting DSL metadata
4. No performance overhead (happens once at class definition time)
5. Zero breaking changes to existing code

## TDD Implementation Plan

### Step 1: Write Comprehensive Test Suite

**Create:** `test/test_custom_methods.rb`

#### Test Cases

1. **Basic instance method**
   ```ruby
   def test_instance_method_with_attribute_access
     User = Structure.new do
       attribute :age, Integer
       def adult?
         age >= 18
       end
     end

     assert User.parse(age: 25).adult?
     refute User.parse(age: 10).adult?
   end
   ```

2. **Basic class method**
   ```ruby
   def test_class_method
     User = Structure.new do
       attribute :role, String
       def self.create_admin
         parse(role: "admin")
       end
     end

     assert_equal "admin", User.create_admin.role
   end
   ```

3. **Multiple instance methods**
   ```ruby
   def test_multiple_instance_methods
     Person = Structure.new do
       attribute :first_name, String
       attribute :last_name, String

       def full_name
         "#{first_name} #{last_name}"
       end

       def initials
         "#{first_name[0]}#{last_name[0]}"
       end
     end

     p = Person.parse(first_name: "John", last_name: "Doe")
     assert_equal "John Doe", p.full_name
     assert_equal "JD", p.initials
   end
   ```

4. **Methods with type coercion**
   ```ruby
   def test_custom_methods_with_type_coercion
     Product = Structure.new do
       attribute :price, Float
       attribute :quantity, Integer

       def total
         price * quantity
       end
     end

     p = Product.parse(price: "19.99", quantity: "3")
     assert_equal 59.97, p.total
   end
   ```

5. **Methods with key mapping (`from:`)**
   ```ruby
   def test_custom_methods_with_key_mapping
     User = Structure.new do
       attribute :active, :boolean, from: "IsActive"

       def status
         active ? "online" : "offline"
       end
     end

     assert_equal "online", User.parse("IsActive" => "true").status
     assert_equal "offline", User.parse("IsActive" => "false").status
   end
   ```

6. **Methods with default values**
   ```ruby
   def test_custom_methods_with_defaults
     Config = Structure.new do
       attribute :timeout, Integer, default: 30

       def timeout_ms
         timeout * 1000
       end
     end

     assert_equal 30000, Config.parse({}).timeout_ms
   end
   ```

7. **Methods with optional attributes (`attribute?`)**
   ```ruby
   def test_custom_methods_with_optional_attributes
     User = Structure.new do
       attribute :name, String
       attribute? :nickname, String

       def display_name
         nickname || name
       end
     end

     assert_equal "Bob", User.parse(name: "Robert", nickname: "Bob").display_name
     assert_equal "Robert", User.parse(name: "Robert").display_name
   end
   ```

8. **Methods with transformation blocks**
   ```ruby
   def test_custom_methods_with_transformation_blocks
     Order = Structure.new do
       attribute :total do |val|
         val.to_f.round(2)
       end

       def formatted_total
         "$#{total}"
       end
     end

     assert_equal "$19.99", Order.parse(total: "19.989").formatted_total
   end
   ```

9. **Methods with `after_parse` callback**
   ```ruby
   def test_custom_methods_with_after_parse
     calls = []

     User = Structure.new do
       attribute :age, Integer

       def valid?
         age > 0
       end

       after_parse do |user|
         calls << user.valid?
       end
     end

     User.parse(age: 25)
     assert_equal [true], calls
   end
   ```

10. **Overriding Data methods**
    ```ruby
    def test_overriding_data_methods
      Person = Structure.new do
        attribute :name, String

        def to_s
          "Person: #{name}"
        end
      end

      assert_equal "Person: Alice", Person.parse(name: "Alice").to_s
    end
    ```

11. **Methods with nested structures**
    ```ruby
    def test_custom_methods_with_nested_structures
      Address = Structure.new do
        attribute :city, String
        attribute :country, String
      end

      User = Structure.new do
        attribute :name, String
        attribute :address, Address

        def location
          "#{address.city}, #{address.country}"
        end
      end

      u = User.parse(name: "Alice", address: { city: "Boston", country: "USA" })
      assert_equal "Boston, USA", u.location
    end
    ```

12. **Methods with array types**
    ```ruby
    def test_custom_methods_with_array_types
      Project = Structure.new do
        attribute :tags, [String]

        def tag_count
          tags.length
        end

        def has_tag?(tag)
          tags.include?(tag)
        end
      end

      p = Project.parse(tags: ["ruby", "gem", "testing"])
      assert_equal 3, p.tag_count
      assert p.has_tag?("ruby")
      refute p.has_tag?("python")
    end
    ```

13. **Class and instance methods together**
    ```ruby
    def test_class_and_instance_methods_together
      User = Structure.new do
        attribute :name, String
        attribute :age, Integer

        def adult?
          age >= 18
        end

        def self.legal_age
          18
        end
      end

      assert_equal 18, User.legal_age
      assert User.parse(name: "Bob", age: 25).adult?
    end
    ```

14. **Methods preserve Data functionality**
    ```ruby
    def test_methods_preserve_data_functionality
      Person = Structure.new do
        attribute :name, String
        attribute :age, Integer

        def greeting
          "Hi!"
        end
      end

      p = Person.parse(name: "Alice", age: 30)

      # Data methods still work
      assert_equal [:name, :age], p.class.members
      assert_equal({ name: "Alice", age: 30 }, p.to_h)
      assert_equal "Alice", p.name
      assert_equal 30, p.age

      # Custom method works
      assert_equal "Hi!", p.greeting
    end
    ```

15. **Methods with self-referential types**
    ```ruby
    def test_custom_methods_with_self_referential_types
      Tree = Structure.new do
        attribute :value, String
        attribute :children, [:self], default: []

        def leaf?
          children.empty?
        end

        def depth
          return 1 if leaf?
          1 + children.map(&:depth).max
        end
      end

      tree = Tree.parse(
        value: "root",
        children: [
          { value: "child1", children: [{ value: "grandchild" }] },
          { value: "child2" }
        ]
      )

      refute tree.leaf?
      assert tree.children[1].leaf?
      assert_equal 3, tree.depth
    end
    ```

**Run tests:** `bundle exec rake test`
**Expected:** All new tests fail with `NoMethodError` for custom methods

### Step 2: Implement Feature

**File:** `lib/structure.rb`

**Location:** After line 26 (after `klass = Data.define(*builder.attributes)`)

**Add:**
```ruby
# Enable custom method definitions by evaluating block on the class
if block
  # Provide temporary dummy DSL methods to prevent NoMethodError during class_eval
  klass.define_singleton_method(:attribute) { |*args, **kwargs, &blk| }
  klass.define_singleton_method(:attribute?) { |*args, **kwargs, &blk| }
  klass.define_singleton_method(:after_parse) { |&blk| }

  # Evaluate block in class context for method definitions
  klass.class_eval(&block)

  # Remove temporary DSL methods
  klass.singleton_class.send(:remove_method, :attribute)
  klass.singleton_class.send(:remove_method, :attribute?)
  klass.singleton_class.send(:remove_method, :after_parse)
end
```

**Full context (lines ~22-50):**
```ruby
def new(&block)
  builder = Builder.new
  builder.instance_eval(&block) if block

  # @type var klass: untyped
  klass = Data.define(*builder.attributes)

  # Enable custom method definitions by evaluating block on the class
  if block
    # Provide temporary dummy DSL methods to prevent NoMethodError during class_eval
    klass.define_singleton_method(:attribute) { |*args, **kwargs, &blk| }
    klass.define_singleton_method(:attribute?) { |*args, **kwargs, &blk| }
    klass.define_singleton_method(:after_parse) { |&blk| }

    # Evaluate block in class context for method definitions
    klass.class_eval(&block)

    # Remove temporary DSL methods
    klass.singleton_class.send(:remove_method, :attribute)
    klass.singleton_class.send(:remove_method, :attribute?)
    klass.singleton_class.send(:remove_method, :after_parse)
  end

  # Override initialize to make optional attributes truly optional
  optional_attrs = builder.optional
  unless optional_attrs.empty?
    klass.class_eval do
      alias_method(:__data_initialize__, :initialize)

      define_method(:initialize) do |**kwargs| # steep:ignore
        optional_attrs.each do |attr|
          kwargs[attr] = nil unless kwargs.key?(attr)
        end
        __data_initialize__(**kwargs) # steep:ignore
      end
    end
  end

  # ... rest of method unchanged
```

**Run tests:** `bundle exec rake test`
**Expected:** All tests pass

### Step 3: Verify No Regressions

**Run full suite:** `bundle exec rake`
**Expected:** All existing tests pass + RuboCop passes

### Step 4: Update Documentation

**File:** `README.md`

**Add new section after "After Parse Callbacks":**

```markdown
### Custom Methods

Define instance and class methods directly in the Structure block, just like `Data.define`:

```ruby
User = Structure.new do
  attribute :name, String
  attribute :age, Integer
  attribute :active, :boolean

  # Instance methods
  def adult?
    age >= 18
  end

  def greeting
    "Hello, I'm #{name}"
  end

  def status
    active ? "online" : "offline"
  end

  # Class methods
  def self.create_guest
    parse(name: "Guest", age: 0, active: false)
  end
end

user = User.parse(name: "Alice", age: 25, active: true)
user.adult?      # => true
user.greeting    # => "Hello, I'm Alice"
user.status      # => "online"

guest = User.create_guest
guest.name       # => "Guest"
guest.adult?     # => false
```

Custom methods work seamlessly with all Structure features including type coercion, key mapping, defaults, optional attributes, nested structures, and arrays.

```ruby
Product = Structure.new do
  attribute :name, String
  attribute :price, Float
  attribute :tags, [String]
  attribute? :discount, Float

  def discounted_price
    return price unless discount
    price * (1 - discount)
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def self.categories
    ["electronics", "books", "clothing"]
  end
end

product = Product.parse(
  name: "Laptop",
  price: "999.99",
  tags: ["electronics", "computers"],
  discount: "0.1"
)

product.discounted_price  # => 899.991
product.has_tag?("electronics")  # => true
Product.categories  # => ["electronics", "books", "clothing"]
```
```

### Step 5: Update Changelog

**File:** `CHANGELOG.md`

**Add under "Unreleased" or next version:**

```markdown
## [Unreleased]

### Added

- Support for defining custom instance and class methods within `Structure.new` blocks, matching `Data.define` behavior (#XX)
  ```ruby
  User = Structure.new do
    attribute :age, Integer

    def adult?
      age >= 18
    end

    def self.legal_age
      18
    end
  end
  ```
```

## Edge Cases & Considerations

### Handled

✅ **Multiple method definitions** - All methods defined in block are preserved
✅ **Type coercion** - Methods can access coerced attribute values
✅ **Key mapping** - Methods access attributes by their Ruby names, not source keys
✅ **Defaults** - Methods see default values when attributes are missing
✅ **Optional attributes** - Methods can handle nil values from optional attributes
✅ **Nested structures** - Methods can traverse nested Structure objects
✅ **Arrays** - Methods can iterate and manipulate array attributes
✅ **Self-referential** - Methods work with recursive structures
✅ **Overriding Data methods** - Can override `to_s`, `to_h`, etc.
✅ **Data functionality preserved** - All Data methods (`members`, `to_h`, etc.) still work
✅ **after_parse callback** - Custom methods can be called from callbacks
✅ **Transformation blocks** - Methods access transformed values
✅ **Boolean predicates** - Auto-generated predicates (`active?`) still work
✅ **Pattern matching** - Data's pattern matching still works

### Limitations

⚠️ **Block evaluated twice** - Minor overhead at class definition time only (not at runtime)
⚠️ **No access to Builder** - Methods cannot access Builder metadata directly (this is expected behavior)

### Not Breaking

✅ **Existing code** - All existing Structure usage continues to work unchanged
✅ **Performance** - No runtime overhead, only one-time class definition cost
✅ **API** - No changes to public API surface

## Testing Strategy

### Unit Tests (test/test_custom_methods.rb)
- 15 comprehensive test cases covering all features
- Edge cases with nested structures, arrays, self-referential types
- Integration with all DSL features

### Integration Tests (existing test suite)
- All existing tests must pass without modification
- Verifies no regressions

### Manual Testing
```ruby
# Quick smoke test
Person = Structure.new do
  attribute :name, String
  attribute :age, Integer

  def adult?
    age >= 18
  end

  def self.test_class_method
    "works"
  end
end

p = Person.parse(name: "Alice", age: 25)
p.adult?  # => true
Person.test_class_method  # => "works"
```

## Implementation Checklist

- [ ] Create `test/test_custom_methods.rb` with 15 test cases
- [ ] Run tests, verify they fail appropriately
- [ ] Modify `lib/structure.rb` to add two-pass evaluation
- [ ] Run tests, verify all pass
- [ ] Run `bundle exec rake` to verify no regressions
- [ ] Update `README.md` with new "Custom Methods" section
- [ ] Update `CHANGELOG.md` with feature addition
- [ ] Create feature branch with descriptive name (e.g., `feature/custom-method-definitions`)
- [ ] Stage files explicitly: `git add test/test_custom_methods.rb lib/structure.rb README.md CHANGELOG.md`
- [ ] Commit with conventional commit message: `feat: add support for custom method definitions in Structure blocks`
- [ ] Verify tests pass in CI

## Alternatives Considered

### Alternative 1: Use Module#prepend
**Approach:** Capture method definitions in a module, prepend to Data class
**Rejected:** More complex, unnecessary indirection

### Alternative 2: Parse block source code
**Approach:** Parse Ruby source to separate DSL from methods
**Rejected:** Fragile, requires external dependencies, complex

### Alternative 3: Separate method block parameter
**Approach:** `Structure.new(methods: -> { def foo; end })`
**Rejected:** Less ergonomic, doesn't match Data.define behavior

### Alternative 4: Method definition DSL
**Approach:** `method :adult? { age >= 18 }`
**Rejected:** Unfamiliar syntax, doesn't match Ruby conventions

### Chosen: Two-pass evaluation
**Why:** Simple, clean, matches Data.define, zero dependencies, no breaking changes

## Success Criteria

✅ All 15 new tests pass
✅ All existing tests continue to pass
✅ RuboCop passes
✅ Documentation updated
✅ Zero breaking changes
✅ Feature matches Data.define behavior
✅ Code remains idiomatic and maintainable

## Timeline Estimate

- Write tests: 30 minutes
- Implement feature: 10 minutes
- Update docs: 15 minutes
- Testing & verification: 10 minutes
- **Total: ~65 minutes**

## Future Enhancements (Out of Scope)

- RBS type signature generation for custom methods
- Steep type checking for custom methods
- Documentation generation for custom methods
- IDE autocomplete support (would require language server changes)
