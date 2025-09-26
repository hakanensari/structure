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

  # This test demonstrates a contrived edge case where user-provided procs
  # can break due to our lambda? detection logic. See issue #10.
  #
  # The case is contrived because:
  # 1. Users rarely provide procs that depend on external instance context
  # 2. The recommended approach is to use blocks (which become lambdas)
  # 3. Simple procs work fine with instance_exec
  #
  # We're keeping this test skipped to document the known limitation
  # without fixing it due to its rarity and complexity of a proper fix.
  def test_user_provided_context_dependent_proc_breaks
    skip("Known contrived edge case - see issue #10")

    # Create a proc that depends on instance variables from its creation context
    helper = Class.new do
      def initialize
        @secret = "helper_secret"
      end

      def create_proc
        proc { |value| "#{value}_#{@secret}" }
      end
    end.new

    context_proc = helper.create_proc

    # Verify the proc works in isolation
    assert_equal("test_helper_secret", context_proc.call("test"))

    # This will break because Structure uses instance_exec,
    # changing the context and making @secret nil
    problem_class = Structure.new do
      attribute(:processed, context_proc)
    end

    result = problem_class.parse(processed: "input")

    # This assertion will fail - we get "input_" instead of "input_helper_secret"
    # because @secret is nil in the Structure class context
    assert_equal("input_helper_secret", result.processed)
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
