# frozen_string_literal: true

require "prism"

module RbsMacros
  # An environment for the Ruby program being analyzed.
  class Environment
    attr_reader :rbs, :object_class, :decls

    def initialize
      @rbs = RBS::Environment.new
      @object_class = MetaClass.new(self, "Object", is_class: true)
      @decls = []
      @exact_handlers = {}
    end

    def register_handler(name, handler)
      (@exact_handlers[name.to_sym] ||= []) << handler
    end

    def invoke(params)
      handlers = @exact_handlers[params.name]
      handlers&.each do |handler|
        handler.(params)
      end
    end

    def meta_eval_ruby(code, filename:)
      result = Prism.parse(code, filepath: "#{filename}.rb")
      raise ArgumentError, "Parse error: #{result.errors}" if result.failure?

      ExecCtx.new(
        env: self,
        filename:,
        self: nil, # TODO
        cref: @object_class,
        cref_dynamic: @object_class,
        locals: {}
      ).eval_node(result.value)
    end

    def add_decl(decl, mod:, file:)
      @decls << DeclarationEntry.new(declaration: decl, mod:, file:)
    end

    HandlerParams = _ = Data.define(:env, :filename, :receiver, :name, :positional, :keyword, :block) # rubocop:disable Naming/ConstantName

    DeclarationEntry = _ = Data.define(:declaration, :mod, :file) # rubocop:disable Naming/ConstantName
  end
end
