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
end

task default: %i[test rubocop steep]
