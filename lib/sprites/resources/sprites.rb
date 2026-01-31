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

      def create(name:) = @client.post("/v1/sprites", { name: }).then(&Sprite)

      def update(name, **attrs) = @client.put("/v1/sprites/#{name}", attrs).then(&Sprite)
    end
  end
end
