# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def test_sprites_list_empty
    VCR.use_cassette("sprites_list_empty") do
      client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
      response = client.sprites.list

      assert_kind_of Sprites::Collection, response
      assert_empty response.sprites
    end
  end

  def test_sprites_list_with_data
    VCR.use_cassette("sprites_list_with_data") do
      client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
      response = client.sprites.list

      assert_kind_of Sprites::Collection, response
      refute_empty response.sprites

      sprite = response.sprites.first
      assert_equal "sprite-00000000-0000-0000-0000-000000000001", sprite[:id]
      assert_equal "my-sprite", sprite[:name]
      assert_equal "warm", sprite[:status]
      assert_equal "https://my-sprite-xxxx.sprites.app", sprite[:url]
      assert_equal "test-org", sprite[:organization]
      assert sprite.key?(:created_at)
      assert sprite.key?(:updated_at)
    end
  end
end
