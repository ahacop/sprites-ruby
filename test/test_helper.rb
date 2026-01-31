# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "debug"

require "dotenv"
Dotenv.load(".env.test.local")

require "sprites"

require "minitest/autorun"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<SPRITES_TOKEN>") { ENV["SPRITES_TOKEN"] }
end
