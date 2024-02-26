# frozen_string_literal: true

require_relative "test_helper"

class LibraryRegistryTest < Minitest::Test
  def test_register_array
    registry = RbsMacros::LibraryRegistry.new
    registry.register_macros("lib", ["foo", "bar"])

    assert_equal ["foo", "bar"], registry.lookup_macros("lib")
  end

  def test_register_block
    registry = RbsMacros::LibraryRegistry.new
    registry.register_macros("lib") do |macros|
      macros << "foo"
      macros << "bar"
    end

    assert_equal ["foo", "bar"], registry.lookup_macros("lib")
  end

  def test_register_empty
    registry = RbsMacros::LibraryRegistry.new
    registry.register_macros("lib")

    assert_empty registry.lookup_macros("lib")
  end

  def test_register_multiple
    registry = RbsMacros::LibraryRegistry.new
    registry.register_macros("lib", ["foo"])
    registry.register_macros("lib") do |macros|
      macros << "bar"
    end
    registry.register_macros("lib", ["baz"])
    registry.register_macros("lib") do |macros|
      macros << "quux"
    end

    assert_equal ["foo", "bar", "baz", "quux"], registry.lookup_macros("lib")
  end

  def test_lookup_missing
    registry = RbsMacros::LibraryRegistry.new

    assert_empty registry.lookup_macros("lib", soft_fail: true)
    assert_raises(ArgumentError) do
      registry.lookup_macros("lib")
    end
  end

  def test_lookup_require
    registry = RbsMacros::LibraryRegistry.new
    def registry.require_library(name, soft_fail: false)
      case name
      when "lib"
        register_macros("lib", ["foo"])
      else; super
      end
    end

    assert_equal ["foo"], registry.lookup_macros("lib")
  end

  def test_lookup_require_fail
    registry = RbsMacros::LibraryRegistry.new
    def registry.require_library(name, soft_fail: false)
      case name
      when "fail-lib"
        raise LoadError unless soft_fail
      else; super
      end
    end

    assert_raises(LoadError) do
      registry.lookup_macros("fail-lib")
    end
  end

  def test_lookup_require_no_registration
    registry = RbsMacros::LibraryRegistry.new
    def registry.require_library(name, soft_fail: false)
      case name
      when "nolib"
        # no-op
      else; super
      end
    end

    assert_raises(ArgumentError) do
      registry.lookup_macros("nolib")
    end
  end

  def test_lookup_require_soft
    registry = RbsMacros::LibraryRegistry.new
    def registry.require_library(name, soft_fail: false)
      case name
      when "lib"
        register_macros("lib", ["foo"])
      else; super
      end
    end

    assert_equal ["foo"], registry.lookup_macros("lib", soft_fail: true)
  end
end
