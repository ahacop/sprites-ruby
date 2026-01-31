# frozen_string_literal: true

module Sprites
  module Resources
    class Sprites
      def initialize(client)
        @client = client
      end

      def list
        @client.get("/v1/sprites") => { sprites:, has_more:, next_continuation_token: }
        Collection.new(sprites:, has_more:, next_continuation_token:)
      end
    end
  end
end
