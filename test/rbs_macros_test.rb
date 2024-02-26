# frozen_string_literal: true

require_relative "test_helper"

class RbsMacrosTest < Minitest::Test
  def test_version_number
    assert_kind_of String, RbsMacros::VERSION
  end
end
