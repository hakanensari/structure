# frozen_string_literal: true

require 'minitest/autorun'
require 'structure'
require 'person'
begin
  require 'pry'
rescue LoadError
  nil
end

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
