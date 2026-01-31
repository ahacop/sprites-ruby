# frozen_string_literal: true

require "test_helper"

class TestExec < Minitest::Test
  def setup
    @client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
  end

  private attr_reader :client

  def test_exec_create
    VCR.use_cassette("exec_create") do
      sprite = client.sprites.create(name: "exec-test-sprite")
      result = client.exec.create(sprite.name, command: "echo hello")

      assert_equal 0, result[:exit_code]
      assert_equal "hello\n", result[:output]

      client.sprites.delete(sprite.name)
    end
  end

  def test_exec_create_sprite_not_found
    VCR.use_cassette("exec_create_not_found") do
      assert_raises Sprites::Error do
        client.exec.create("nonexistent-sprite", command: "echo hello")
      end
    end
  end
end
