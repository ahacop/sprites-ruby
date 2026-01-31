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

    def get(path) = handle_response(connection.get(path))

    def post(path, body) = handle_response(connection.post(path, body.to_json, "Content-Type" => "application/json"))

    private

    def handle_response(response)
      body = JSON.parse(response.body, symbolize_names: true)

      return body if response.success?

      message = body[:error] || body[:errors]&.join(", ") || "Unknown error"
      raise Error, message
    end

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :authorization, "Bearer", @token
      end
    end
  end
end
