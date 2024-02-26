# frozen_string_literal: true

require "prism"

module RbsMacros
  # An environment for the Ruby program being analyzed.
  class Environment
    attr_reader :object_class

    def initialize
      @object_class = MetaClass.new(self, "Object", is_class: true)
    end

    def meta_eval_ruby(code)
      result = Prism.parse(code)
      raise ArgumentError, "Parse error: #{result.errors}" if result.failure?

      meta_eval_ruby_node(result.value)
    end

    def meta_eval_ruby_node(node)
      case node
      when Prism::ClassNode
        klass = MetaClass.new(self, node.name.to_s, is_class: true)
        @object_class.meta_const_set(node.name, klass)
      when Prism::ProgramNode
        meta_eval_ruby_node(node.statements)
      when Prism::StatementsNode
        node.body.each { |stmt| meta_eval_ruby_node(stmt) }
        # else
        # $stderr.puts "Dismissing node: #{node.inspect}"
      end
    end
  end
end
