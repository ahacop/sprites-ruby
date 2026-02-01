# frozen_string_literal: true

module Sprites
  module Resources
    # Network policy operations.
    class Policies
      def initialize(client)
        @client = client
      end

      # Get current network policy for a sprite.
      #
      # @param sprite_name [String] sprite name
      # @return [Hash] policy with :egress settings
      def retrieve(sprite_name)
        @client.get("/v1/sprites/#{sprite_name}/policies")
      end

      # Update network policy for a sprite.
      #
      # @param sprite_name [String] sprite name
      # @param attrs [Hash] policy attributes (:egress)
      # @return [Hash] updated policy
      def update(sprite_name, **attrs)
        @client.post("/v1/sprites/#{sprite_name}/policies", attrs)
      end
    end
  end
end
