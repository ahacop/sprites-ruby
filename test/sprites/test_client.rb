# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    @client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
  end

  private attr_reader :client

  def test_sprites_list_empty
    VCR.use_cassette("sprites_list_empty") do
      response = client.sprites.list

      assert_kind_of Sprites::Collection, response
      assert_empty response.sprites
    end
  end

  def test_sprites_list_with_data
    VCR.use_cassette("sprites_list_with_data") do
      response = client.sprites.list

      assert_kind_of Sprites::Collection, response
      refute_empty response.sprites

      sprite = response.sprites.first
      assert_kind_of Sprites::Sprite, sprite
      assert_equal "sprite-00000000-0000-0000-0000-000000000001", sprite.id
      assert_equal "my-sprite", sprite.name
      assert_equal "warm", sprite.status
      assert_equal "https://my-sprite-xxxx.sprites.app", sprite.url
      assert_equal "test-org", sprite.organization
      assert sprite.created_at
      assert sprite.updated_at
    end
  end

  def test_sprites_retrieve
    VCR.use_cassette("sprites_retrieve") do
      sprite = client.sprites.retrieve("test-sprite")

      assert_kind_of Sprites::Sprite, sprite
      assert_equal "sprite-00000000-0000-0000-0000-000000000001", sprite.id
      assert_equal "my-sprite", sprite.name
      assert_equal "warm", sprite.status
      assert_equal "https://my-sprite-xxxx.sprites.app", sprite.url
      assert_equal "test-org", sprite.organization
      assert sprite.created_at
      assert sprite.updated_at
    end
  end

  def test_sprites_create
    VCR.use_cassette("sprites_create") do
      sprite = client.sprites.create(name: "new-sprite")

      assert_kind_of Sprites::Sprite, sprite
      assert_equal "new-sprite", sprite.name
      assert sprite.id
      assert sprite.url
    end
  end

  def test_sprites_create_duplicate_name
    VCR.use_cassette("sprites_create_duplicate") do
      client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])

      assert_raises Sprites::Error do
        client.sprites.create(name: "test-sprite")
      end
    end
  end

  def test_sprites_create_empty_name
    VCR.use_cassette("sprites_create_empty_name") do
      client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])

      assert_raises Sprites::Error do
        client.sprites.create(name: "")
      end
    end
  end

  def test_sprites_retrieve_not_found
    VCR.use_cassette("sprites_retrieve_not_found") do
      assert_raises Sprites::Error do
        client.sprites.retrieve("nonexistent-sprite")
      end
    end
  end

  def test_sprites_list_invalid_token
    VCR.use_cassette("sprites_list_invalid_token") do
      client = Sprites::Client.new(token: "invalid-token")

      assert_raises Sprites::Error do
        client.sprites.list
      end
    end
  end

  def test_sprites_update
    VCR.use_cassette("sprites_update") do
      sprite = client.sprites.update("test-sprite", url_settings: { auth: "public" })

      assert_kind_of Sprites::Sprite, sprite
      assert_equal "test-sprite", sprite.name
      assert_equal({ auth: "public" }, sprite.url_settings)
    end
  end

  def test_sprites_update_invalid_value
    VCR.use_cassette("sprites_update_invalid") do
      assert_raises Sprites::Error do
        client.sprites.update("test-sprite", url_settings: { auth: "invalid" })
      end
    end
  end
end
