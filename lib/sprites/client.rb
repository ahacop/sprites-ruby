# frozen_string_literal: true

require "faraday"
require "json"

module Sprites
  class Client
    def initialize(token: nil, base_url: nil)
      @token = token || Sprites.configuration.token
      @base_url = base_url || Sprites.configuration.base_url
    end

    def sprites
      Resources::Sprites.new(self)
    end

    def get(path) = parse_json(connection.get(path))

    private

    def parse_json(response) = JSON.parse(response.body, symbolize_names: true)

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :authorization, "Bearer", @token
      end
    end
  end
end
