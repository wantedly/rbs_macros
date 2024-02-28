# frozen_string_literal: true

module RbsMacros
  # Base class for macro implementations.
  # Macros react to method invocations in Ruby code (usually in module/class bodies)
  # and generate RBS declarations for them.
  class Macro
    def setup(env) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "Not implemented: #{self.class}#setup"
    end
  end
end
