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
    loader = RBS::EnvironmentLoader.new
    fs = DummyFS.new
    RbsMacros.run(macros:, loader:, fs:) do |env|
      buffer = RBS::Buffer.new(name: "foo.rbs", content: <<~RBS)
        module Foo
          extend Forwardable
          @contents: Array[String]
        end
      RBS
      _, directives, decls = RBS::Parser.parse_signature(buffer)
      env.rbs.add_signature(buffer:, directives:, decls:)
      env.instance_variable_set(:@rbs, env.rbs.resolve_type_names)
      env.meta_eval_ruby(<<~RUBY)
        module Foo
          extend Forwardable
          def_delegator(:@contents, :[], "content_at")
        end
      RUBY
    end

    assert_equal <<~RBS, fs.read("sig/foo.rbs")
      module Foo
        def content_at: (::int index) -> ::String
                      | (::int start, ::int length) -> ::Array[::String]?
                      | (::Range[::Integer?] range) -> ::Array[::String]?
      end
    RBS
  end
end
