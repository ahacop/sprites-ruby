# frozen_string_literal: true

module Sprites
  module Resources
    # Checkpoint operations for sprite snapshots.
    class Checkpoints
      def initialize(client)
        @client = client
      end

      # List all checkpoints for a sprite.
      #
      # @param sprite_name [String] sprite name
      # @return [Array<Hash>] checkpoints
      def list(sprite_name)
        @client.get("/v1/sprites/#{sprite_name}/checkpoints")
      end

      # Retrieve a checkpoint by ID.
      #
      # @param sprite_name [String] sprite name
      # @param checkpoint_id [String] checkpoint ID
      # @return [Hash] checkpoint details
      def retrieve(sprite_name, checkpoint_id)
        @client.get("/v1/sprites/#{sprite_name}/checkpoints/#{checkpoint_id}")
      end

      # Create a new checkpoint.
      #
      # @param sprite_name [String] sprite name
      # @param comment [String, nil] optional comment
      # @yield [Hash] streaming NDJSON events
      # @return [Array<Hash>] all events if no block given
      def create(sprite_name, comment: nil, &block)
        @client.post_stream("/v1/sprites/#{sprite_name}/checkpoint", { comment: }, &block)
      end

      # Restore a sprite to a checkpoint.
      #
      # @param sprite_name [String] sprite name
      # @param checkpoint_id [String] checkpoint ID
      # @yield [Hash] streaming NDJSON events
      # @return [Array<Hash>] all events if no block given
      def restore(sprite_name, checkpoint_id, &block)
        @client.post_stream("/v1/sprites/#{sprite_name}/checkpoints/#{checkpoint_id}/restore", {}, &block)
      end
    end
  end
end
