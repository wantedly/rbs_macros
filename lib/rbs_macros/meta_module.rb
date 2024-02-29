# frozen_string_literal: true

module RbsMacros
  # Designates a module in a Ruby program being analyzed.
  class MetaModule
    attr_reader :env, :name, :is_class, :superclass

    def initialize(env, name, is_class: nil, superclass: nil)
      @env = env
      @name = name
      @is_class = is_class
      @superclass = superclass
      @constants = {}
    end

    def rbs_type
      return @rbs_type if defined?(@rbs_type)

      *ns, name = (@name || raise("Anonymous module given")).split("::")
      @rbs_type = RBS::TypeName.new(
        name: (name || raise("Anonymous module gien")).to_sym,
        namespace: RBS::Namespace.new(
          path: ns.map(&:to_sym),
          absolute: true
        )
      )
    end

    def meta_const_set(name, value)
      @constants[name] = value
    end

    def meta_const_get(name)
      @constants[name]
    end

    def meta_constants
      @constants.keys
    end
  end

  MetaClass = MetaModule
end
