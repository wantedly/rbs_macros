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

    def meta_const_set(name, value)
      @constants[name] = value
    end

    def meta_const_get(name)
      @constants[name]
    end
  end

  MetaClass = MetaModule
end
