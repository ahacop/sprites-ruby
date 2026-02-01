# frozen_string_literal: true

module Sprites
  module Resources
    class Sprites
      def initialize(client)
        @client = client
      end

      def list
        @client.get("/v1/sprites") => { sprites:, has_more:, next_continuation_token: }
        sprites = sprites.map(&Sprite)
        Collection.new(sprites:, has_more:, next_continuation_token:)
      end

      def retrieve(name) = @client.get("/v1/sprites/#{name}").then(&Sprite)

      def create(name:, wait: false, timeout: 60)
        sprite = @client.post("/v1/sprites", { name: }).then(&Sprite)
        wait ? wait_until_warm(sprite.name, timeout:) : sprite
      end

      def wait_until_warm(name, timeout: 60)
        deadline = Time.now + timeout
        loop do
          sprite = retrieve(name)
          return sprite if sprite.status == "warm"
          raise Error, "Timed out waiting for sprite to become warm" if Time.now > deadline

          sleep 0.5
        end
      end

      def update(name, **attrs) = @client.put("/v1/sprites/#{name}", attrs).then(&Sprite)

      def delete(name) = @client.delete("/v1/sprites/#{name}")
    end
  end
end
