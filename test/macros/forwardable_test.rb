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

  def test_run
    macros = [RbsMacros::Macros::ForwardableMacros.new]
    fs = DummyFS.new
    RbsMacros.run(macros:, fs:) do |env|
      env.meta_eval_ruby(<<~RUBY)
        module Foo
          extend Forwardable
          def_delegator(:@contents, :[], "content_at")
        end
      RUBY
    end

    assert_equal <<~RBS, fs.read("sig/foo.rbs")
      module Foo
        def content_at: () -> void
      end
    RBS
  end
end
