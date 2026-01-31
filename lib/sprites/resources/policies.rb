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

      def update(sprite_name, **attrs)
        @client.post("/v1/sprites/#{sprite_name}/policies", attrs)
      end
    end
  end
end
