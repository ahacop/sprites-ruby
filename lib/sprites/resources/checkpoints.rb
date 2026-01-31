# frozen_string_literal: true

module Sprites
  module Resources
    class Checkpoints
      def initialize(client)
        @client = client
      end

      def create(sprite_name, comment: nil, &block)
        @client.post_stream("/v1/sprites/#{sprite_name}/checkpoint", { comment: }, &block)
      end
    end
  end
end
