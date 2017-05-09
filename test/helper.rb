require "minitest/autorun"
require_relative "../lib/structure"

module Minitest
  class Test
    private

    def build_anonymous_class(&blk)
      Class.new do
        include Structure

        class_eval(&blk) if block_given?
      end
    end
  end
end
