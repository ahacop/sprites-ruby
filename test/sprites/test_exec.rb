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

  def test_exec_list
    VCR.use_cassette("exec_list") do
      sprite = client.sprites.create(name: "exec-list-sprite")
      sessions = client.exec.list(sprite.name)

      assert_equal 2, sessions.length

      assert_equal 1847, sessions[0][:id]
      assert_equal "bash", sessions[0][:command]
      assert_equal true, sessions[0][:is_active]
      assert_equal true, sessions[0][:tty]
      assert_equal "/home/sprite/myproject", sessions[0][:workdir]

      assert_equal 1923, sessions[1][:id]
      assert_equal "python -m http.server 8000", sessions[1][:command]
      assert_equal false, sessions[1][:is_active]

      client.sprites.delete(sprite.name)
    end
  end

  def test_exec_kill
    VCR.use_cassette("exec_kill") do
      sprite = client.sprites.create(name: "exec-kill-sprite")
      events = client.exec.kill(sprite.name, 1847)

      assert_equal 3, events.length
      assert_equal "signal", events[0][:type]
      assert_equal "SIGTERM", events[0][:signal]
      assert_equal 1847, events[0][:pid]
      assert_equal "exited", events[1][:type]
      assert_equal "complete", events[2][:type]
      assert_equal 0, events[2][:exit_code]

      client.sprites.delete(sprite.name)
    end
  end

  def test_websocket_url
    assert_equal "wss://api.sprites.dev", client.websocket_url
  end

  def test_auth_headers
    assert_equal [["authorization", "Bearer #{ENV['SPRITES_TOKEN']}"]], client.auth_headers
  end
end
