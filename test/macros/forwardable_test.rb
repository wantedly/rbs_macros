# frozen_string_literal: true

require_relative "../test_helper"
require "rbs_macros/macros/forwardable"

class ForwardableTest < Minitest::Test
  class DummyFS
    def initialize
      @files = {}
    end

    def read(path)
      @files[path] || raise(Errno::ENOENT, path)
    end

    def write(path, content)
      @files[path] = content
    end
  end

  def test_forwardable
    project = RbsMacros::FakeProject.new
    project.write("lib/foo.rb", <<~RBS)
      module Foo
        extend Forwardable
        def_delegator(:@contents, :[], "content_at")
      end
    RBS
    project.write("sig/foo.rbs", <<~RBS)
      module Foo
        extend Forwardable
        @contents: Array[String]
      end
    RBS
    RbsMacros.run do |config|
      config.project = project
      config.macros << RbsMacros::Macros::ForwardableMacros.new
    end

    assert_equal <<~RBS, project.read("sig/generated/foo.rbs")
      module Foo
        def content_at: (::int index) -> ::String
                      | (::int start, ::int length) -> ::Array[::String]?
                      | (::Range[::Integer?] range) -> ::Array[::String]?
      end
    RBS
  end

  def test_def_delegators
    project = RbsMacros::FakeProject.new
    project.write("lib/array_wrapper.rb", <<~RBS)
      class ArrayWrapper
        extend Forwardable
        def_delegators :@storage, :[], :size
      end
    RBS
    project.write("sig/array_wrapper.rbs", <<~RBS)
      class ArrayWrapper[T]
        extend Forwardable
        @storage: Array[T]
      end
    RBS
    RbsMacros.run do |config|
      config.project = project
      config.macros << RbsMacros::Macros::ForwardableMacros.new
    end

    assert_equal <<~RBS, project.read("sig/generated/array_wrapper.rbs")
      class ArrayWrapper[T]
        def []: (::int index) -> T
              | (::int start, ::int length) -> ::Array[T]?
              | (::Range[::Integer?] range) -> ::Array[T]?

        def size: () -> ::Integer
      end
    RBS
  end

  def test_def_single_delegator
    project = RbsMacros::FakeProject.new
    project.write("lib/singleton_pattern.rb", <<~RBS)
      class SingletonPattern
        extend SingleForwardable
        def_single_delegator :@singleton, :query, :singleton_query
        def_single_delegator :@singleton, :length
      end
    RBS
    project.write("sig/singleton_pattern.rbs", <<~RBS)
      class SingletonPattern[T]
        extend SingleForwardable
        self.@singleton: SingletonPattern[Numeric]

        def query: () -> T
        def length: () -> Integer
      end
      module SingleForwardable
      end
    RBS
    RbsMacros.run do |config|
      config.project = project
      config.macros << RbsMacros::Macros::SingleForwardableMacros.new
    end

    assert_equal <<~RBS, project.read("sig/generated/singleton_pattern.rbs")
      class SingletonPattern[T]
        def self.singleton_query: () -> ::Numeric

        def self.length: () -> ::Integer
      end
    RBS
  end
end
