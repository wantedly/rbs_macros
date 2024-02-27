# frozen_string_literal: true

require_relative "test_helper"

class RbsMacrosTest < Minitest::Test
  def test_version_number
    assert_kind_of String, RbsMacros::VERSION
  end

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

  def test_run
    fs = DummyFS.new
    RbsMacros.run(fs:)

    assert_equal <<~RBS, fs.read("sig/foo.rbs")
      module Foo
        def method_defined_from_macro: () -> void

        module Bar
          def method_defined_from_macro: () -> void
        end
      end
    RBS
  end
end
