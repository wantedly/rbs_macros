# frozen_string_literal: true

module RbsMacros
  # Designates a module in a Ruby program being analyzed.
  class MetaModule
    attr_reader :env, :name, :is_class, :superclass

    def initialize(env, name, is_class: nil, superclass: nil)
      @env = env
      @name = name
      @is_class = is_class
      @superclass = superclass
      @constants = {}
    end

    def meta_send(name:, positional:, keyword:, block:) # rubocop:disable Lint/UnusedMethodArgument
      if name == :my_macro
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
          mod: self,
          file: "foo"
        )
      else # rubocop:disable Style/EmptyElse
        # TODO
      end
    end

    def meta_const_set(name, value)
      @constants[name] = value
    end

    def meta_const_get(name)
      @constants[name]
    end

    def meta_constants
      @constants.keys
    end
  end

  MetaClass = MetaModule
end
