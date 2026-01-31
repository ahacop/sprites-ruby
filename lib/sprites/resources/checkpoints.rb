# frozen_string_literal: true

module Sprites
  module Resources
    class Checkpoints
      def initialize(client)
        @client = client
      end

      def list(sprite_name)
        @client.get("/v1/sprites/#{sprite_name}/checkpoints")
      end

      def retrieve(sprite_name, checkpoint_id)
        @client.get("/v1/sprites/#{sprite_name}/checkpoints/#{checkpoint_id}")
      end

      def create(sprite_name, comment: nil, &block)
        @client.post_stream("/v1/sprites/#{sprite_name}/checkpoint", { comment: }, &block)
      end
    end
  end
end
