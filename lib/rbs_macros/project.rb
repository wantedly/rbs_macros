# frozen_string_literal: true

require "fileutils"
require "pathname"

module RbsMacros
  # Refers to the filesystem RbsMacros operates on.
  class AbstractProject
    # rubocop:disable Lint/UnusedMethodArgument
    def glob(
      ext:,
      include:,
      exclude:,
      &block
    )
      raise NoMethodError, "Not implemented: #{self.class}#each_rbs"
    end

    def write(path, content)
      raise NoMethodError, "Not implemented: #{self.class}#write"
    end

    def read(path)
      raise NoMethodError, "Not implemented: #{self.class}#read"
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end

  # A project based on real FS.
  class Project < AbstractProject
    attr_accessor :base_dir

    def initialize(base_dir: Pathname(Dir.pwd))
      super()
      @base_dir = base_dir
    end

    def glob(
      ext:,
      include:,
      exclude:,
      &block
    )
      return enum_for(:glob, ext:, include:, exclude:) unless block

      loaded = Set.new # : Set[String]
      include.each do |incl_dir|
        Dir.glob(
          "#{incl_dir}/**/*#{ext}",
          base: @base_dir
        ).sort.each do |path|
          next unless File.file?(@base_dir + path)
          next if loaded.include?(path)

          loaded << path
          is_excluded = exclude.any? do |excl_dir|
            "#{path}/".start_with?("#{excl_dir}/")
          end
          block.(path) unless is_excluded
        end
      end
    end

    def write(path, content)
      full_path = @base_dir + path
      FileUtils.mkdir_p(full_path.dirname)
      File.write(full_path.to_s, content)
    end
  end

  # An in-memory project.
  class FakeProject < AbstractProject
    def initialize
      super
      @files = {}
    end

    def glob(
      ext:,
      include:,
      exclude:,
      &block
    )
      return enum_for(:glob, ext:, include:, exclude:) unless block

      @files.each_key do |path|
        has_ext = path.end_with?(ext)
        is_incl = include.any? do |incl_dir|
          "#{path}/".start_with?("#{incl_dir}/")
        end
        is_excl = exclude.any? do |excl_dir|
          "#{path}/".start_with?("#{excl_dir}/")
        end
        block.(path) if has_ext && is_incl && !is_excl
      end
    end

    def write(path, content)
      @files[path] = content
    end

    def read(path)
      @files[path] || raise(Errno::ENOENT, path)
    end
  end
end
