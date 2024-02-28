# frozen_string_literal: true

require "rbs_macros"

module RbsMacros
  module Macros
    # Implements macros for the `Forwardable` module.
    class ForwardableMacros < Macro
      def setup(env)
        env.register_handler(:def_delegator, method(:meta_def_delegator))
        env.register_handler(:def_instance_delegator, method(:meta_def_delegator))
      end

      def meta_def_delegator(params)
        recv = params.receiver
        return unless recv.is_a?(MetaModule)

        # accessor = params.positional[0]
        method = params.positional[1]
        ali = params.positional[2] || method
        return unless ali.is_a?(Symbol) || ali.is_a?(String)

        params.env.add_decl(
          RBS::AST::Members::MethodDefinition.new(
            name: ali.to_sym,
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
      end
    end
  end
end

RbsMacros::LibraryRegistry.register_macros("rbs_macros/macros/forwardable") do |macros|
  macros << RbsMacros::Macros::ForwardableMacros
end
