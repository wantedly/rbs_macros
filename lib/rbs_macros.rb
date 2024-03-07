# frozen_string_literal: true

require_relative "rbs_macros/version"
require_relative "rbs_macros/config"
require_relative "rbs_macros/environment"
require_relative "rbs_macros/exec_ctx"
require_relative "rbs_macros/library_registry"
require_relative "rbs_macros/macro"
require_relative "rbs_macros/meta_module"
require_relative "rbs_macros/project"

require "stringio"
require "rbs"

# RbsMacros is a utility that looks for metaprogramming-related
# method invocation in your Ruby code and generates RBS files for them.
module RbsMacros
  def self.run(&block)
    config = Config.new
    block&.(config)

    rbs = RBS::Environment.new
    config.loader.load(env: rbs) if config.use_loader
    config.project.glob(ext: ".rbs", include: config.sigs, exclude: [config.output_dir]) do |filename|
      source = config.project.read(filename)
      buffer = RBS::Buffer.new(name: filename, content: source)
      _, directives, decls = RBS::Parser.parse_signature(buffer)
      rbs.add_signature(buffer:, directives:, decls:)
    end
    rbs = rbs.resolve_type_names

    env = Environment.new(rbs:)
    config.macros.each do |macro|
      macro.setup(env)
    end

    config.project.glob(ext: ".rb", include: config.load_dirs, exclude: []) do |filename|
      relative_filename = filename
      config.load_dirs.each do |load_dir|
        if filename.start_with?("#{load_dir}/")
          relative_filename = filename.delete_prefix("#{load_dir}/")
          break
        end
      end
      source = config.project.read(filename)
      env.meta_eval_ruby(source, filename: relative_filename.sub(/\.rb\z/, ""))
    end

    files = {} # : Hash[String, Array[RBS::AST::Declarations::t]]
    env.decls.each do |entry|
      file_decls = (files[entry.file] ||= [])
      current_mod = env.object_class
      container = nil # : (RBS::AST::Declarations::Module | RBS::AST::Declarations::Class)?
      (entry.mod.name || "").split("::").each do |name|
        inner_mod = current_mod.meta_const_get(name.to_sym)
        raise "Not found: #{current_mod.name}::#{name}" unless inner_mod
        raise "Not a module: #{current_mod.name}::#{name}" unless inner_mod.is_a?(MetaModule)

        current_mod = inner_mod

        current_decls = container&.members || file_decls
        container = nil
        current_decls.each do |decl|
          if (decl.is_a?(RBS::AST::Declarations::Class) || decl.is_a?(RBS::AST::Declarations::Module)) \
            && decl.name.name == name.to_sym
            container = decl
          end
        end
        next if container

        type_params = env.rbs.class_decls[current_mod.rbs_type]&.type_params || []

        if inner_mod.is_class
          container = c = RBS::AST::Declarations::Class.new(
            name: RBS::TypeName.new(name: name.to_sym, namespace: RBS::Namespace.empty),
            type_params:,
            super_class: nil,
            members: [],
            annotations: [],
            location: nil,
            comment: nil
          )
          current_decls << c
        else
          container = m = RBS::AST::Declarations::Module.new(
            name: RBS::TypeName.new(name: name.to_sym, namespace: RBS::Namespace.empty),
            type_params:,
            members: [],
            self_types: [],
            annotations: [],
            location: nil,
            comment: nil
          )
          current_decls << m
        end
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
      config.project.write("#{config.output_dir}/#{filename}.rbs", out.string)
    end
  end
end
