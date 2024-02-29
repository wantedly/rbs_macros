# frozen_string_literal: true

module RbsMacros
  ExecCtx = _ = Data.define(:env, :filename, :self, :cref, :cref_dynamic, :locals) # rubocop:disable Naming/ConstantName

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
        positional = [] # : Array[Object]
        keyword = {} # : Hash[Object, Object]
        node.arguments&.arguments&.each do |arg|
          positional << eval_node(arg)
        end
        env.invoke(
          Environment::HandlerParams.new(
            env:,
            filename:,
            receiver: recv,
            name: node.name,
            positional:,
            keyword:,
            block: nil
          )
        )
      when Prism::ClassNode
        klass = cref.define_module(node.name)
        klass.class!
        with(
          self: klass,
          cref: klass,
          cref_dynamic: klass,
          locals: {}
        ).eval_node(node.body)
      when Prism::ModuleNode
        mod = cref.define_module(node.name)
        mod.module!
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
      when Prism::StringNode
        node.unescaped.dup.freeze
      when Prism::SymbolNode
        node.unescaped.to_sym
      else
        $stderr.puts "Dismissing node: #{node.inspect}" # rubocop:disable Style/StderrPuts
      end
    end
  end
end
