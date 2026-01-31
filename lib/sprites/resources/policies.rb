# frozen_string_literal: true

module Sprites
  module Resources
    class Policies
      def initialize(client)
        @client = client
      end

      def retrieve(sprite_name)
        @client.get("/v1/sprites/#{sprite_name}/policies")
      end
    end
  end
end
