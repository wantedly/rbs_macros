# frozen_string_literal: true

module RbsMacros
  ExecCtx = _ = Data.define(:env, :self, :cref, :cref_dynamic, :locals) # rubocop:disable Naming/ConstantName

  # Context, including self, class, and local variables
  class ExecCtx
    def eval_node(node)
      case node
      when Prism::ClassNode
        klass = MetaClass.new(env, node.name.to_s, is_class: true)
        env.object_class.meta_const_set(node.name, klass)
      when Prism::ModuleNode
        mod = MetaModule.new(env, node.name.to_s, is_class: false)
        env.object_class.meta_const_set(node.name, mod)
      when Prism::ProgramNode
        eval_node(node.statements)
      when Prism::StatementsNode
        node.body.each { |stmt| eval_node(stmt) }
        # else
        # $stderr.puts "Dismissing node: #{node.inspect}"
      end
    end
  end
end
