# frozen_string_literal: true

require "test_helper"

class TestCheckpoints < Minitest::Test
  def setup
    @client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
  end

  private attr_reader :client

  def test_checkpoints_create
    VCR.use_cassette("checkpoints_create") do
      sprite = client.sprites.create(name: "checkpoint-test-sprite")
      events = client.checkpoints.create(sprite.name, comment: "test checkpoint")

      assert_kind_of Array, events
      assert events.any? { |e| e[:type] == "complete" }

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_create_with_block
    VCR.use_cassette("checkpoints_create_with_block") do
      sprite = client.sprites.create(name: "checkpoint-block-sprite")
      yielded_events = []
      client.checkpoints.create(sprite.name, comment: "test checkpoint") do |event|
        yielded_events << event
      end

      refute_empty yielded_events
      assert yielded_events.all? { |e| e.key?(:type) }

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_create_sprite_not_found
    VCR.use_cassette("checkpoints_create_not_found") do
      assert_raises Sprites::Error do
        client.checkpoints.create("nonexistent-sprite", comment: "test")
      end
    end
  end

  def test_checkpoints_list
    VCR.use_cassette("checkpoints_list") do
      sprite = client.sprites.create(name: "checkpoint-list-sprite")
      client.checkpoints.create(sprite.name, comment: "first checkpoint")
      client.checkpoints.create(sprite.name, comment: "second checkpoint")

      checkpoints = client.checkpoints.list(sprite.name)

      assert_kind_of Array, checkpoints
      assert checkpoints.all? { |c| c.key?(:id) && c.key?(:create_time) && c.key?(:is_auto) }

      first = checkpoints.find { |c| c[:comment] == "first checkpoint" }
      second = checkpoints.find { |c| c[:comment] == "second checkpoint" }

      refute_nil first
      assert_equal "v1", first[:id]
      assert_equal false, first[:is_auto]

      refute_nil second
      assert_equal "v2", second[:id]
      assert_equal false, second[:is_auto]

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_retrieve
    VCR.use_cassette("checkpoints_retrieve") do
      sprite = client.sprites.create(name: "checkpoint-retrieve-sprite")
      client.checkpoints.create(sprite.name, comment: "retrieve test")

      checkpoint = client.checkpoints.retrieve(sprite.name, "v1")

      assert_equal "v1", checkpoint[:id]
      assert_equal "retrieve test", checkpoint[:comment]
      assert_equal false, checkpoint[:is_auto]
      assert checkpoint.key?(:create_time)

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_list_sprite_not_found
    VCR.use_cassette("checkpoints_list_not_found") do
      assert_raises Sprites::Error do
        client.checkpoints.list("nonexistent-sprite")
      end
    end
  end

  def test_checkpoints_retrieve_sprite_not_found
    VCR.use_cassette("checkpoints_retrieve_sprite_not_found") do
      assert_raises Sprites::Error do
        client.checkpoints.retrieve("nonexistent-sprite", "v1")
      end
    end
  end

  def test_checkpoints_retrieve_checkpoint_not_found
    VCR.use_cassette("checkpoints_retrieve_checkpoint_not_found") do
      sprite = client.sprites.create(name: "checkpoint-not-found-sprite")

      assert_raises Sprites::Error do
        client.checkpoints.retrieve(sprite.name, "nonexistent")
      end

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_restore
    VCR.use_cassette("checkpoints_restore") do
      sprite = client.sprites.create(name: "checkpoint-restore-sprite")
      client.checkpoints.create(sprite.name, comment: "restore test")

      events = client.checkpoints.restore(sprite.name, "v1")

      assert_equal 3, events.size

      assert_equal "info", events[0][:type]
      assert_equal "Restoring from checkpoint v1...", events[0][:data]

      assert_equal "info", events[1][:type]
      assert_equal "Container components started successfully", events[1][:data]

      assert_equal "complete", events[2][:type]
      assert_equal "Restore from v1 complete", events[2][:data]

      client.sprites.delete(sprite.name)
    end
  end

  def test_checkpoints_restore_checkpoint_not_found
    VCR.use_cassette("checkpoints_restore_not_found") do
      sprite = client.sprites.create(name: "checkpoint-restore-not-found-sprite")

      assert_raises Sprites::Error do
        client.checkpoints.restore(sprite.name, "nonexistent")
      end

      client.sprites.delete(sprite.name)
    end
  end
end
