# frozen_string_literal: true

module RbsMacros
  ExecCtx = _ = Data.define(:env, :self, :cref, :cref_dynamic, :locals) # rubocop:disable Naming/ConstantName

  # Context, including self, class, and local variables
  class ExecCtx
    def eval_node(node)
      case node
      when nil
        # do nothing
      when Prism::CallNode
        recv = \
          if node.receiver
            eval_node(node.receiver)
          else
            self.self
          end
        recv.meta_send(name: node.name, positional: [], keyword: {}, block: nil) if recv.is_a?(MetaModule)
      when Prism::ClassNode
        klass = MetaClass.new(env, module_name(cref, node.name.to_s), is_class: true)
        cref.meta_const_set(node.name, klass)
        with(
          self: klass,
          cref: klass,
          cref_dynamic: klass,
          locals: {}
        ).eval_node(node.body)
      when Prism::ModuleNode
        mod = MetaModule.new(env, module_name(cref, node.name.to_s), is_class: false)
        cref.meta_const_set(node.name, mod)
        with(
          self: mod,
          cref: mod,
          cref_dynamic: mod,
          locals: {}
        ).eval_node(node.body)
      when Prism::ProgramNode
        eval_node(node.statements)
      when Prism::StatementsNode
        node.body.each { |stmt| eval_node(stmt) }
      else
        $stderr.puts "Dismissing node: #{node.inspect}" # rubocop:disable Style/StderrPuts
      end
    end

    private

    def module_name(parent, name)
      if name && (parent.name && parent.name != "Object")
        "#{parent.name}::#{name}"
      elsif name
        name
      end
    end
  end
end
