# frozen_string_literal: true

require "prism"

module RbsMacros
  # An environment for the Ruby program being analyzed.
  class Environment
    attr_reader :object_class, :decls

    def initialize
      @object_class = MetaClass.new(self, "Object", is_class: true)
      @decls = []
    end

    def meta_eval_ruby(code)
      result = Prism.parse(code)
      raise ArgumentError, "Parse error: #{result.errors}" if result.failure?

      ExecCtx.new(
        env: self,
        self: nil, # TODO
        cref: @object_class,
        cref_dynamic: @object_class,
        locals: {}
      ).eval_node(result.value)
    end

    def add_decl(decl, mod:, file:)
      @decls << DeclarationEntry.new(declaration: decl, mod:, file:)
    end

    DeclarationEntry = _ = Data.define(:declaration, :mod, :file) # rubocop:disable Naming/ConstantName
  end
end
