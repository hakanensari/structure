# frozen_string_literal: true

require_relative "helper"
require "structure"

class TestProcEdgeCases < Minitest::Test
  def test_user_provided_lambda_works_correctly
    # Lambdas work fine - they use .call() directly
    upcase_lambda = ->(value) { value.to_s.upcase }

    person_class = Structure.new do
      attribute(:name, upcase_lambda)
    end

    person = person_class.parse(name: "alice")

    assert_equal("ALICE", person.name)
  end

  def test_user_provided_simple_proc_works_by_accident
    # Simple procs work fine even with instance_exec
    # because they don't depend on external context
    upcase_proc = proc { |value| value.to_s.upcase }

    person_class = Structure.new do
      attribute(:name, upcase_proc)
    end

    person = person_class.parse(name: "alice")

    assert_equal("ALICE", person.name)
  end

  # Simple failing test demonstrating proc context issue - see issue #10
  def test_proc_loses_context_with_instance_exec
    skip("Known edge case - procs lose original context with instance_exec")

    # Proc that expects access to local variable
    secret = "original_context"
    user_proc = proc { |value| "#{value}_#{secret}" }

    # Works in original context
    assert_equal("test_original_context", user_proc.call("test"))

    # Breaks when Structure uses instance_exec (context changes)
    klass = Structure.new do
      attribute(:result, user_proc)
    end

    result = klass.parse(result: "input")
    # This fails because secret is undefined in Structure's context
    assert_equal("input_original_context", result.result)
  end

  def test_workaround_for_context_dependent_transformation
    # Users can work around this by using blocks instead of pre-created procs
    secret = "block_secret"

    working_class = Structure.new do
      attribute(:processed) do |value|
        # This block captures the local variable correctly
        "#{value}_#{secret}"
      end
    end

    result = working_class.parse(processed: "input")

    assert_equal("input_block_secret", result.processed)
  end
end
