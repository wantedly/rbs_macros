# frozen_string_literal: true

require "rbs_macros"

module RbsMacros
  module Macros
    # TODO: resolve duplication between ForwardableMacros and SingleForwardableMacros
    # TODO: fallback to untyped even when something is wrong

    # Implements macros for the `Forwardable` module.
    class ForwardableMacros < Macro
      def setup(env)
        env.register_handler(:def_delegator, method(:meta_def_delegator))
        env.register_handler(:def_instance_delegator, method(:meta_def_delegator))

        env.register_handler(:def_delegators, method(:meta_def_delegators))
        env.register_handler(:def_instance_delegators, method(:meta_def_delegators))
      end

      def meta_def_delegator(params)
        recv = params.receiver
        return unless recv.is_a?(MetaModule)

        accessor = params.positional[0]
        method = params.positional[1]
        ali = params.positional[2] || method
        return unless accessor.is_a?(Symbol) || accessor.is_a?(String)
        return unless method.is_a?(Symbol) || method.is_a?(String)
        return unless ali.is_a?(Symbol) || ali.is_a?(String)

        builder = RBS::DefinitionBuilder.new(env: params.env.rbs)
        self_instance = builder.build_instance(recv.rbs_type)
        accessor_type =
          case accessor.to_s
          when /\A@/
            ivar = self_instance.instance_variables[accessor.to_sym]
            return unless ivar

            ivar.type
          else
            # TODO
            return
          end
        accessor_instance = widened_instance(accessor_type, builder:)
        return unless accessor_instance

        meth = accessor_instance[0].methods[method.to_sym]&.sub(accessor_instance[1])
        return unless meth

        params.env.add_decl(
          RBS::AST::Members::MethodDefinition.new(
            name: ali.to_sym,
            kind: :instance,
            overloads:
              meth.defs.map do |typedef|
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: typedef.type,
                  annotations: []
                )
              end,
            annotations: [],
            location: nil,
            comment: nil,
            overloading: false,
            visibility: nil
          ),
          mod: recv,
          file: params.filename
        )
      end

      def meta_def_delegators(params)
        recv = params.receiver
        return unless recv.is_a?(MetaModule)

        accessor = params.positional[0]
        methods = params.positional[1..] || []
        methods.each do |method|
          params.env.invoke(
            params.with(
              name: :def_instance_delegator,
              positional: [accessor, method],
              keyword: {},
              block: nil
            )
          )
        end
      end

      private

      def widened_instance(type, builder:)
        case type
        when RBS::Types::ClassInstance
          # Using public_send because tapp_subst is declared as private although defined as public.
          [builder.build_instance(type.name), builder.public_send(:tapp_subst, type.name, type.args)]
        end
      end
    end

    # Implements macros for the `SingleForwardable` module.
    class SingleForwardableMacros < Macro
      def setup(env)
        env.register_handler(:def_delegator, method(:meta_def_delegator))
        env.register_handler(:def_single_delegator, method(:meta_def_delegator))

        env.register_handler(:def_delegators, method(:meta_def_delegators))
        env.register_handler(:def_single_delegators, method(:meta_def_delegators))
      end

      def meta_def_delegator(params)
        recv = params.receiver
        return unless recv.is_a?(MetaModule)

        accessor = params.positional[0]
        method = params.positional[1]
        ali = params.positional[2] || method
        return unless accessor.is_a?(Symbol) || accessor.is_a?(String)
        return unless method.is_a?(Symbol) || method.is_a?(String)
        return unless ali.is_a?(Symbol) || ali.is_a?(String)

        builder = RBS::DefinitionBuilder.new(env: params.env.rbs)
        singleton = builder.build_singleton(recv.rbs_type)
        accessor_type =
          case accessor.to_s
          when /\A@/
            ivar = singleton.instance_variables[accessor.to_sym]
            return unless ivar

            ivar.type
          else
            # TODO
            return
          end
        accessor_instance = widened_instance(accessor_type, builder:)
        return unless accessor_instance

        meth = accessor_instance[0].methods[method.to_sym]&.sub(accessor_instance[1])
        return unless meth

        params.env.add_decl(
          RBS::AST::Members::MethodDefinition.new(
            name: ali.to_sym,
            kind: :singleton,
            overloads:
              meth.defs.map do |typedef|
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: typedef.type,
                  annotations: []
                )
              end,
            annotations: [],
            location: nil,
            comment: nil,
            overloading: false,
            visibility: nil
          ),
          mod: recv,
          file: params.filename
        )
      end

      def meta_def_delegators(params)
        recv = params.receiver
        return unless recv.is_a?(MetaModule)

        accessor = params.positional[0]
        methods = params.positional[1..] || []
        methods.each do |method|
          params.env.invoke(
            params.with(
              name: :def_single_delegator,
              positional: [accessor, method],
              keyword: {},
              block: nil
            )
          )
        end
      end

      private

      def widened_instance(type, builder:)
        case type
        when RBS::Types::ClassInstance
          # Using public_send because tapp_subst is declared as private although defined as public.
          [builder.build_instance(type.name), builder.public_send(:tapp_subst, type.name, type.args)]
        end
      end
    end
  end
end

RbsMacros::LibraryRegistry.register_macros("rbs_macros/macros/forwardable") do |macros|
  macros << RbsMacros::Macros::ForwardableMacros
  macros << RbsMacros::Macros::SingleForwardableMacros
end
