# frozen_string_literal: true

require "forwardable"

module RbsMacros
  # RbsMacros allow you to define a reusable set of macro definitions
  # called a library.
  # This is usually registered to the global singleton of LibraryRegistry
  # like:
  #
  #   # my_library/rbs_macros.rb
  #   RbsMacros::LibraryRegistry.register_macros("my_library/rbs_macros") do |macros|
  #     macros << MyMacro1
  #     macros << MyMacro2
  #   end
  class LibraryRegistry
    extend SingleForwardable
    def_single_delegators :@global, :register_macros

    def initialize
      @libraries = {}
    end

    def register_macros(name, macros = [], &block)
      a = @libraries.fetch(name) { |k| @libraries[k] = [] }
      a.push(*macros)
      block&.(a)
      nil
    end

    def lookup_macros(name, soft_fail: false)
      unless @libraries.key?(name)
        require_library(name, soft_fail:)
        raise ArgumentError, "Unknown library: #{name}" if !@libraries.key?(name) && !soft_fail
      end

      @libraries[name] || []
    end

    def require_library(name, soft_fail: false)
      # To be implemented by subclasses
      raise ArgumentError, "Unknown library: #{name}" unless soft_fail
    end

    class << self
      @global = LibraryRegistry.new
      def @global.require_library(name, soft_fail: false)
        require name
      rescue LoadError
        raise unless soft_fail
      end
    end
  end
end
