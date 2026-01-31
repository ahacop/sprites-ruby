# frozen_string_literal: true

require "test_helper"

class TestPolicies < Minitest::Test
  def setup
    @client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
  end

  private attr_reader :client

  def test_policies_retrieve
    VCR.use_cassette("policies_retrieve") do
      sprite = client.sprites.create(name: "policy-test-sprite")
      policy = client.policies.retrieve(sprite.name)

      assert_equal "allow-all", policy[:egress][:policy]

      client.sprites.delete(sprite.name)
    end
  end

  def test_policies_retrieve_sprite_not_found
    VCR.use_cassette("policies_retrieve_not_found") do
      assert_raises Sprites::Error do
        client.policies.retrieve("nonexistent-sprite")
      end
    end
  end

  def test_policies_update
    VCR.use_cassette("policies_update") do
      sprite = client.sprites.create(name: "policy-update-sprite")
      policy = client.policies.update(sprite.name, egress: { policy: "block-all" })

      assert_equal "block-all", policy[:egress][:policy]

      client.sprites.delete(sprite.name)
    end
  end

  def test_policies_update_sprite_not_found
    VCR.use_cassette("policies_update_not_found") do
      assert_raises Sprites::Error do
        client.policies.update("nonexistent-sprite", egress: { policy: "block-all" })
      end
    end
  end
end
