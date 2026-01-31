# frozen_string_literal: true

module Sprites
  module Resources
    class Exec
      def initialize(client)
        @client = client
      end

      def create(sprite_name, command:)
        @client.post("/v1/sprites/#{sprite_name}/exec", { command: })
      end
    end
  end
end
