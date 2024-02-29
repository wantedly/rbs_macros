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

  class DummyMacro < RbsMacros::Macro
    def setup(env)
      env.register_handler(:my_macro, lambda { |params|
        recv = params.receiver
        next unless recv.is_a?(RbsMacros::MetaModule)

        env.add_decl(
          RBS::AST::Members::MethodDefinition.new(
            name: :method_defined_from_macro,
            kind: :instance,
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: RBS::MethodType.new(
                  type_params: [],
                  type: RBS::Types::Function.new(
                    required_positionals: [],
                    optional_positionals: [],
                    rest_positionals: nil,
                    trailing_positionals: [],
                    required_keywords: {},
                    optional_keywords: {},
                    rest_keywords: nil,
                    return_type: RBS::Types::Bases::Void.new(location: nil)
                  ),
                  block: nil,
                  location: nil
                ),
                annotations: []
              )
            ],
            annotations: [],
            location: nil,
            comment: nil,
            overloading: false,
            visibility: nil
          ),
          mod: recv,
          file: "foo"
        )
      })
    end
  end

  def test_run
    project = RbsMacros::FakeProject.new
    project.write("lib/foo.rb", <<~RBS)
      module Foo
        my_macro :foo
        module Bar
          my_macro :bar
        end
      end

      class MyClass
        my_macro :foo
      end
    RBS
    RbsMacros.run do |config|
      config.project = project
      config.macros << DummyMacro.new
    end

    assert_equal <<~RBS, project.read("sig/foo.rbs")
      module Foo
        def method_defined_from_macro: () -> void

        module Bar
          def method_defined_from_macro: () -> void
        end
      end

      class MyClass
        def method_defined_from_macro: () -> void
      end
    RBS
  end
end
