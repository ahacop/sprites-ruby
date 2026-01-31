# frozen_string_literal: true

module Sprites
  module Resources
    class Sprites
      def initialize(client)
        @client = client
      end

      def list
        @client.get("/v1/sprites") => { sprites:, has_more:, next_continuation_token: }
        Collection.new(
          sprites: sprites.map { Sprite.new(**_1) },
          has_more:,
          next_continuation_token:
        )
      end

      def retrieve(name)
        Sprite.new(**@client.get("/v1/sprites/#{name}"))
      end

      def create(name:)
        Sprite.new(**@client.post("/v1/sprites", { name: }))
      end
    end
  end
end
