# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def teardown
    Sprites.reset_configuration
  end

  def test_configure_with_block
    Sprites.configure do |config|
      config.token = "test_token"
    end

    assert_equal "test_token", Sprites.configuration.token
  end

  def test_default_base_url
    assert_equal "https://api.sprites.dev", Sprites.configuration.base_url
  end

  def test_configure_base_url
    Sprites.configure do |config|
      config.base_url = "https://custom.example.com"
    end

    assert_equal "https://custom.example.com", Sprites.configuration.base_url
  end
end
