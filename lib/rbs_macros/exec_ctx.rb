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
        return nil if recv.nil? && node.safe_navigation?

        positional = [] # : Array[Object?]
        keyword = {} # : Hash[Object?, Object?]
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
        result = nil # TODO
        return positional[0] if node.attribute_write?

        result
      when Prism::ClassNode
        klass = eval_module_read(node.constant_path)
        return unless klass.is_a?(MetaModule)

        # TODO: evaluate superclass

        klass.class!
        with(
          self: klass,
          cref: klass,
          cref_dynamic: klass,
          locals: init_locals(node.locals)
        ).eval_node(node.body)
      when Prism::ModuleNode
        mod = eval_module_read(node.constant_path)
        return unless mod.is_a?(MetaModule)

        mod.module!
        with(
          self: mod,
          cref: mod,
          cref_dynamic: mod,
          locals: init_locals(node.locals)
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

    def eval_module_read(node)
      case node
      when Prism::ConstantReadNode
        # Foo as in `class Foo` or `Foo::Bar`.
        # Assume Foo exists and is a module.
        #
        # TODO: check for cref stack in case other than class/module expressions
        cref.define_module(node.name)
      when Prism::ConstantPathNode
        base =
          if node.parent
            # node = `Foo::Bar` and parent = `Foo`
            eval_module_read(node.parent)
          else
            # node = `::Foo`
            env.object_class
          end

        child = node.child
        raise TypeError, "Not a ConstantReadNode: #{child.class}" unless child.is_a?(Prism::ConstantReadNode)

        if base.is_a?(MetaModule)
          # Assume that the constant exists and is a module
          base.define_module(child.name)
        end
      else
        eval_node(node)
      end
    end

    private

    def init_locals(locals)
      locals.each_with_object({}) { |name, hash| hash[name] = nil } # $ Hash[Symbol, Object?]
    end
  end
end
