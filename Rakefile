# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.test_files = Dir["test/**/*_test.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Run Steep type checker"
task steep: :"steep:setup" do
  sh "bundle exec steep check"
end
namespace :steep do
  desc "Fetch necessary files for Steep"
  task :setup do
    sh "bundle exec rbs collection install"
  end

  desc "Generate RBS files using macros"
  task :gen do
    require "rbs_macros"
    require "rbs_macros/macros/forwardable"
    RbsMacros.run do |config|
      lock_path = Pathname("rbs_collection.lock.yaml")
      config.loader.add_collection(
        RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: lock_path,
          data: YAML.load_file(lock_path.to_s)
        )
      )
      config.macros << RbsMacros::Macros::SingleForwardableMacros.new
    end
  end
end

task default: %i[test rubocop steep]
