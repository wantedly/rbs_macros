# frozen_string_literal: true

module RbsMacros
  # Configuration for RbsMacros execution
  class Config
    attr_reader :macros, :load_dirs, :sigs
    attr_accessor :loader, :use_loader, :project, :output_dir

    def initialize
      @macros = []
      @load_dirs = ["lib"]
      @sigs = ["sig"]
      @loader = RBS::EnvironmentLoader.new
      @use_loader = true
      @project = Project.new
      @output_dir = "sig/generated"
    end
  end
end
