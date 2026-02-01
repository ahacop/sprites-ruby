# frozen_string_literal: true

module Sprites
  module Resources
    # Sprite CRUD operations.
    class Sprites
      def initialize(client)
        @client = client
      end

      # List all sprites.
      #
      # @return [Collection] paginated collection of sprites
      def list
        @client.get("/v1/sprites") => { sprites:, has_more:, next_continuation_token: }
        sprites = sprites.map(&Sprite)
        Collection.new(sprites:, has_more:, next_continuation_token:)
      end

      # Retrieve a sprite by name.
      #
      # @param name [String] sprite name
      # @return [Sprite]
      def retrieve(name) = @client.get("/v1/sprites/#{name}").then(&Sprite)

      # Create a new sprite.
      #
      # @param name [String] sprite name
      # @param wait [Boolean] block until sprite is warm (default: false)
      # @param timeout [Integer] seconds to wait for warm status (default: 60)
      # @return [Sprite]
      def create(name:, wait: false, timeout: 60)
        sprite = @client.post("/v1/sprites", { name: }).then(&Sprite)
        wait ? wait_until_warm(sprite.name, timeout:) : sprite
      end

      # Poll until a sprite becomes warm.
      #
      # @param name [String] sprite name
      # @param timeout [Integer] seconds to wait (default: 60)
      # @return [Sprite]
      # @raise [Error] if timeout is reached
      def wait_until_warm(name, timeout: 60)
        deadline = Time.now + timeout
        loop do
          sprite = retrieve(name)
          return sprite if sprite.status == "warm"
          raise Error, "Timed out waiting for sprite to become warm" if Time.now > deadline

          sleep 0.5
        end
      end

      # Update a sprite.
      #
      # @param name [String] sprite name
      # @param attrs [Hash] attributes to update
      # @return [Sprite]
      def update(name, **attrs) = @client.put("/v1/sprites/#{name}", attrs).then(&Sprite)

      # Delete a sprite.
      #
      # @param name [String] sprite name
      # @return [nil]
      def delete(name) = @client.delete("/v1/sprites/#{name}")
    end
  end
end
