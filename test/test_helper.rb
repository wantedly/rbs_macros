# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__ || raise("no __dir__"))

require "bundler/setup"
require "rbs_macros"

require "minitest/autorun"
