# frozen_string_literal: true

require_relative "rbs_macros/version"
require_relative "rbs_macros/environment"
require_relative "rbs_macros/library_registry"
require_relative "rbs_macros/meta_module"

require "stringio"
require "rbs"

# RbsMacros is a utility that looks for metaprogramming-related
# method invocation in your Ruby code and generates RBS files for them.
module RbsMacros
  def self.run(fs: File)
    env = Environment.new
    env.meta_eval_ruby(<<~RUBY)
      module Foo
        meta_something :foo
      end
    RUBY

    env.object_class.meta_constants.each do |name|
      value = env.object_class.meta_const_get(name)
      next unless value.is_a?(MetaModule)

      env.add_decl(
        RBS::AST::Members::MethodDefinition.new(
          name: :foo,
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
        mod: value,
        file: "foo"
      )
    end

    files = {} # : Hash[String, Array[RBS::AST::Declarations::t]]
    env.decls.each do |entry|
      file_decls = (files[entry.file] ||= [])
      container = nil # : (RBS::AST::Declarations::Module | RBS::AST::Declarations::Class)?
      (entry.mod.name || "").split("::").each do |name|
        current_decls = container&.members || file_decls
        container = nil
        current_decls.each do |decl|
          if (decl.is_a?(RBS::AST::Declarations::Class) || decl.is_a?(RBS::AST::Declarations::Module)) \
            && decl.name.name == name
            container = decl
          end
        end
        next if container

        container = m = RBS::AST::Declarations::Module.new(
          name: RBS::TypeName.new(name: name.to_sym, namespace: RBS::Namespace.empty),
          type_params: [],
          members: [],
          self_types: [],
          annotations: [],
          location: nil,
          comment: nil
        )
        current_decls << m
      end
      if container
        container.members << entry.declaration
      else
        d = entry.declaration
        case d
        when RBS::AST::Declarations::Class,
            RBS::AST::Declarations::Module,
            RBS::AST::Declarations::Interface,
            RBS::AST::Declarations::Constant,
            RBS::AST::Declarations::Global,
            RBS::AST::Declarations::TypeAlias,
            RBS::AST::Declarations::ClassAlias,
            RBS::AST::Declarations::ModuleAlias
          file_decls << d
        else
          raise "Not allowed here: #{d.class}"
        end
      end
    end

    decls = [] # : Array[RBS::AST::Declarations::t]
    env.object_class.meta_constants.each do |name|
      value = env.object_class.meta_const_get(name)
      next unless value.is_a?(MetaModule)

      decls << RBS::AST::Declarations::Module.new(
        name: RBS::TypeName.new(name:, namespace: RBS::Namespace.empty),
        type_params: [],
        members: [],
        self_types: [],
        annotations: [],
        location: nil,
        comment: nil
      )
    end

    files.each do |filename, file_decls|
      out = StringIO.new(+"", "w")
      writer = RBS::Writer.new(out:)
      writer.write file_decls
      fs.write("sig/#{filename}.rbs", out.string)
    end
  end
end
