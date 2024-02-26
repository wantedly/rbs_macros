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
    decls = [] # : Array[RBS::AST::Declarations::t]
    decls << RBS::AST::Declarations::Module.new(
      name: RBS::TypeName.new(name: :Foo, namespace: RBS::Namespace.empty),
      type_params: [],
      members: [],
      self_types: [],
      annotations: [],
      location: nil,
      comment: nil
    )

    out = StringIO.new(+"", "w")
    writer = RBS::Writer.new(out:)
    writer.write decls
    fs.write("sig/foo.rbs", out.string)
  end
end
