# frozen_string_literal: true

require_relative "test_helper"

class EnvironmentTest < Minitest::Test
  def test_eval_simple_class
    env = RbsMacros::Environment.new
    env.meta_eval_ruby(<<~RUBY, filename: "foo.rb")
      class Foo
      end
    RUBY

    assert_equal "Foo", env.object_class.meta_const_get(:Foo).name
  end
end
